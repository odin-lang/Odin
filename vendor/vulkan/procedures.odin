//
// Vulkan wrapper generated from "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/master/include/vulkan/vulkan_core.h"
//
package vulkan

import "core:c"

// Loader Procedure Types
ProcCreateInstance                       :: #type proc "system" (pCreateInfo: ^InstanceCreateInfo, pAllocator: ^AllocationCallbacks, pInstance: ^Instance) -> Result
ProcDebugUtilsMessengerCallbackEXT       :: #type proc "system" (messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT, pUserData: rawptr) -> b32
ProcDeviceMemoryReportCallbackEXT        :: #type proc "system" (pCallbackData: ^DeviceMemoryReportCallbackDataEXT, pUserData: rawptr)
ProcEnumerateInstanceExtensionProperties :: #type proc "system" (pLayerName: cstring, pPropertyCount: ^u32, pProperties: [^]ExtensionProperties) -> Result
ProcEnumerateInstanceLayerProperties     :: #type proc "system" (pPropertyCount: ^u32, pProperties: [^]LayerProperties) -> Result
ProcEnumerateInstanceVersion             :: #type proc "system" (pApiVersion: ^u32) -> Result

// Misc Procedure Types
ProcAllocationFunction             :: #type proc "system" (pUserData: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
ProcDebugReportCallbackEXT         :: #type proc "system" (flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring, pUserData: rawptr) -> b32
ProcFreeFunction                   :: #type proc "system" (pUserData: rawptr, pMemory: rawptr)
ProcInternalAllocationNotification :: #type proc "system" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
ProcInternalFreeNotification       :: #type proc "system" (pUserData: rawptr, size: int, allocationType: InternalAllocationType, allocationScope: SystemAllocationScope)
ProcReallocationFunction           :: #type proc "system" (pUserData: rawptr, pOriginal: rawptr, size: int, alignment: int, allocationScope: SystemAllocationScope) -> rawptr
ProcVoidFunction                   :: #type proc "system" ()

// Instance Procedure Types
ProcAcquireDrmDisplayEXT                                            :: #type proc "system" (physicalDevice: PhysicalDevice, drmFd: i32, display: DisplayKHR) -> Result
ProcAcquireWinrtDisplayNV                                           :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
ProcCreateDebugReportCallbackEXT                                    :: #type proc "system" (instance: Instance, pCreateInfo: ^DebugReportCallbackCreateInfoEXT, pAllocator: ^AllocationCallbacks, pCallback: ^DebugReportCallbackEXT) -> Result
ProcCreateDebugUtilsMessengerEXT                                    :: #type proc "system" (instance: Instance, pCreateInfo: ^DebugUtilsMessengerCreateInfoEXT, pAllocator: ^AllocationCallbacks, pMessenger: ^DebugUtilsMessengerEXT) -> Result
ProcCreateDevice                                                    :: #type proc "system" (physicalDevice: PhysicalDevice, pCreateInfo: ^DeviceCreateInfo, pAllocator: ^AllocationCallbacks, pDevice: ^Device) -> Result
ProcCreateDisplayModeKHR                                            :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR, pCreateInfo: ^DisplayModeCreateInfoKHR, pAllocator: ^AllocationCallbacks, pMode: ^DisplayModeKHR) -> Result
ProcCreateDisplayPlaneSurfaceKHR                                    :: #type proc "system" (instance: Instance, pCreateInfo: ^DisplaySurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateHeadlessSurfaceEXT                                        :: #type proc "system" (instance: Instance, pCreateInfo: ^HeadlessSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateIOSSurfaceMVK                                             :: #type proc "system" (instance: Instance, pCreateInfo: ^IOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateMacOSSurfaceMVK                                           :: #type proc "system" (instance: Instance, pCreateInfo: ^MacOSSurfaceCreateInfoMVK, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateMetalSurfaceEXT                                           :: #type proc "system" (instance: Instance, pCreateInfo: ^MetalSurfaceCreateInfoEXT, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateWaylandSurfaceKHR                                         :: #type proc "system" (instance: Instance, pCreateInfo: ^WaylandSurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcCreateWin32SurfaceKHR                                           :: #type proc "system" (instance: Instance, pCreateInfo: ^Win32SurfaceCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSurface: ^SurfaceKHR) -> Result
ProcDebugReportMessageEXT                                           :: #type proc "system" (instance: Instance, flags: DebugReportFlagsEXT, objectType: DebugReportObjectTypeEXT, object: u64, location: int, messageCode: i32, pLayerPrefix: cstring, pMessage: cstring)
ProcDestroyDebugReportCallbackEXT                                   :: #type proc "system" (instance: Instance, callback: DebugReportCallbackEXT, pAllocator: ^AllocationCallbacks)
ProcDestroyDebugUtilsMessengerEXT                                   :: #type proc "system" (instance: Instance, messenger: DebugUtilsMessengerEXT, pAllocator: ^AllocationCallbacks)
ProcDestroyInstance                                                 :: #type proc "system" (instance: Instance, pAllocator: ^AllocationCallbacks)
ProcDestroySurfaceKHR                                               :: #type proc "system" (instance: Instance, surface: SurfaceKHR, pAllocator: ^AllocationCallbacks)
ProcEnumerateDeviceExtensionProperties                              :: #type proc "system" (physicalDevice: PhysicalDevice, pLayerName: cstring, pPropertyCount: ^u32, pProperties: [^]ExtensionProperties) -> Result
ProcEnumerateDeviceLayerProperties                                  :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]LayerProperties) -> Result
ProcEnumeratePhysicalDeviceGroups                                   :: #type proc "system" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: [^]PhysicalDeviceGroupProperties) -> Result
ProcEnumeratePhysicalDeviceGroupsKHR                                :: #type proc "system" (instance: Instance, pPhysicalDeviceGroupCount: ^u32, pPhysicalDeviceGroupProperties: [^]PhysicalDeviceGroupProperties) -> Result
ProcEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   :: #type proc "system" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, pCounterCount: ^u32, pCounters: [^]PerformanceCounterKHR, pCounterDescriptions: [^]PerformanceCounterDescriptionKHR) -> Result
ProcEnumeratePhysicalDevices                                        :: #type proc "system" (instance: Instance, pPhysicalDeviceCount: ^u32, pPhysicalDevices: [^]PhysicalDevice) -> Result
ProcGetDisplayModeProperties2KHR                                    :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: [^]DisplayModeProperties2KHR) -> Result
ProcGetDisplayModePropertiesKHR                                     :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR, pPropertyCount: ^u32, pProperties: [^]DisplayModePropertiesKHR) -> Result
ProcGetDisplayPlaneCapabilities2KHR                                 :: #type proc "system" (physicalDevice: PhysicalDevice, pDisplayPlaneInfo: ^DisplayPlaneInfo2KHR, pCapabilities: [^]DisplayPlaneCapabilities2KHR) -> Result
ProcGetDisplayPlaneCapabilitiesKHR                                  :: #type proc "system" (physicalDevice: PhysicalDevice, mode: DisplayModeKHR, planeIndex: u32, pCapabilities: [^]DisplayPlaneCapabilitiesKHR) -> Result
ProcGetDisplayPlaneSupportedDisplaysKHR                             :: #type proc "system" (physicalDevice: PhysicalDevice, planeIndex: u32, pDisplayCount: ^u32, pDisplays: [^]DisplayKHR) -> Result
ProcGetDrmDisplayEXT                                                :: #type proc "system" (physicalDevice: PhysicalDevice, drmFd: i32, connectorId: u32, display: ^DisplayKHR) -> Result
ProcGetInstanceProcAddr                                             :: #type proc "system" (instance: Instance, pName: cstring) -> ProcVoidFunction
ProcGetInstanceProcAddrLUNARG                                       :: #type proc "system" (instance: Instance, pName: cstring) -> ProcVoidFunction
ProcGetPhysicalDeviceCalibrateableTimeDomainsEXT                    :: #type proc "system" (physicalDevice: PhysicalDevice, pTimeDomainCount: ^u32, pTimeDomains: [^]TimeDomainEXT) -> Result
ProcGetPhysicalDeviceCooperativeMatrixPropertiesNV                  :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]CooperativeMatrixPropertiesNV) -> Result
ProcGetPhysicalDeviceDisplayPlaneProperties2KHR                     :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayPlaneProperties2KHR) -> Result
ProcGetPhysicalDeviceDisplayPlanePropertiesKHR                      :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayPlanePropertiesKHR) -> Result
ProcGetPhysicalDeviceDisplayProperties2KHR                          :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayProperties2KHR) -> Result
ProcGetPhysicalDeviceDisplayPropertiesKHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, pPropertyCount: ^u32, pProperties: [^]DisplayPropertiesKHR) -> Result
ProcGetPhysicalDeviceExternalBufferProperties                       :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: [^]ExternalBufferProperties)
ProcGetPhysicalDeviceExternalBufferPropertiesKHR                    :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalBufferInfo: ^PhysicalDeviceExternalBufferInfo, pExternalBufferProperties: [^]ExternalBufferProperties)
ProcGetPhysicalDeviceExternalFenceProperties                        :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: [^]ExternalFenceProperties)
ProcGetPhysicalDeviceExternalFencePropertiesKHR                     :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalFenceInfo: ^PhysicalDeviceExternalFenceInfo, pExternalFenceProperties: [^]ExternalFenceProperties)
ProcGetPhysicalDeviceExternalImageFormatPropertiesNV                :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, externalHandleType: ExternalMemoryHandleTypeFlagsNV, pExternalImageFormatProperties: [^]ExternalImageFormatPropertiesNV) -> Result
ProcGetPhysicalDeviceExternalSemaphoreProperties                    :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: [^]ExternalSemaphoreProperties)
ProcGetPhysicalDeviceExternalSemaphorePropertiesKHR                 :: #type proc "system" (physicalDevice: PhysicalDevice, pExternalSemaphoreInfo: ^PhysicalDeviceExternalSemaphoreInfo, pExternalSemaphoreProperties: [^]ExternalSemaphoreProperties)
ProcGetPhysicalDeviceFeatures                                       :: #type proc "system" (physicalDevice: PhysicalDevice, pFeatures: [^]PhysicalDeviceFeatures)
ProcGetPhysicalDeviceFeatures2                                      :: #type proc "system" (physicalDevice: PhysicalDevice, pFeatures: [^]PhysicalDeviceFeatures2)
ProcGetPhysicalDeviceFeatures2KHR                                   :: #type proc "system" (physicalDevice: PhysicalDevice, pFeatures: [^]PhysicalDeviceFeatures2)
ProcGetPhysicalDeviceFormatProperties                               :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: [^]FormatProperties)
ProcGetPhysicalDeviceFormatProperties2                              :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: [^]FormatProperties2)
ProcGetPhysicalDeviceFormatProperties2KHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, pFormatProperties: [^]FormatProperties2)
ProcGetPhysicalDeviceFragmentShadingRatesKHR                        :: #type proc "system" (physicalDevice: PhysicalDevice, pFragmentShadingRateCount: ^u32, pFragmentShadingRates: [^]PhysicalDeviceFragmentShadingRateKHR) -> Result
ProcGetPhysicalDeviceImageFormatProperties                          :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, tiling: ImageTiling, usage: ImageUsageFlags, flags: ImageCreateFlags, pImageFormatProperties: [^]ImageFormatProperties) -> Result
ProcGetPhysicalDeviceImageFormatProperties2                         :: #type proc "system" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: [^]ImageFormatProperties2) -> Result
ProcGetPhysicalDeviceImageFormatProperties2KHR                      :: #type proc "system" (physicalDevice: PhysicalDevice, pImageFormatInfo: ^PhysicalDeviceImageFormatInfo2, pImageFormatProperties: [^]ImageFormatProperties2) -> Result
ProcGetPhysicalDeviceMemoryProperties                               :: #type proc "system" (physicalDevice: PhysicalDevice, pMemoryProperties: [^]PhysicalDeviceMemoryProperties)
ProcGetPhysicalDeviceMemoryProperties2                              :: #type proc "system" (physicalDevice: PhysicalDevice, pMemoryProperties: [^]PhysicalDeviceMemoryProperties2)
ProcGetPhysicalDeviceMemoryProperties2KHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, pMemoryProperties: [^]PhysicalDeviceMemoryProperties2)
ProcGetPhysicalDeviceMultisamplePropertiesEXT                       :: #type proc "system" (physicalDevice: PhysicalDevice, samples: SampleCountFlags, pMultisampleProperties: [^]MultisamplePropertiesEXT)
ProcGetPhysicalDeviceOpticalFlowImageFormatsNV                      :: #type proc "system" (physicalDevice: PhysicalDevice, pOpticalFlowImageFormatInfo: ^OpticalFlowImageFormatInfoNV, pFormatCount: ^u32, pImageFormatProperties: [^]OpticalFlowImageFormatPropertiesNV) -> Result
ProcGetPhysicalDevicePresentRectanglesKHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pRectCount: ^u32, pRects: [^]Rect2D) -> Result
ProcGetPhysicalDeviceProperties                                     :: #type proc "system" (physicalDevice: PhysicalDevice, pProperties: [^]PhysicalDeviceProperties)
ProcGetPhysicalDeviceProperties2                                    :: #type proc "system" (physicalDevice: PhysicalDevice, pProperties: [^]PhysicalDeviceProperties2)
ProcGetPhysicalDeviceProperties2KHR                                 :: #type proc "system" (physicalDevice: PhysicalDevice, pProperties: [^]PhysicalDeviceProperties2)
ProcGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           :: #type proc "system" (physicalDevice: PhysicalDevice, pPerformanceQueryCreateInfo: ^QueryPoolPerformanceCreateInfoKHR, pNumPasses: [^]u32)
ProcGetPhysicalDeviceQueueFamilyProperties                          :: #type proc "system" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: [^]QueueFamilyProperties)
ProcGetPhysicalDeviceQueueFamilyProperties2                         :: #type proc "system" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: [^]QueueFamilyProperties2)
ProcGetPhysicalDeviceQueueFamilyProperties2KHR                      :: #type proc "system" (physicalDevice: PhysicalDevice, pQueueFamilyPropertyCount: ^u32, pQueueFamilyProperties: [^]QueueFamilyProperties2)
ProcGetPhysicalDeviceSparseImageFormatProperties                    :: #type proc "system" (physicalDevice: PhysicalDevice, format: Format, type: ImageType, samples: SampleCountFlags, usage: ImageUsageFlags, tiling: ImageTiling, pPropertyCount: ^u32, pProperties: [^]SparseImageFormatProperties)
ProcGetPhysicalDeviceSparseImageFormatProperties2                   :: #type proc "system" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: [^]SparseImageFormatProperties2)
ProcGetPhysicalDeviceSparseImageFormatProperties2KHR                :: #type proc "system" (physicalDevice: PhysicalDevice, pFormatInfo: ^PhysicalDeviceSparseImageFormatInfo2, pPropertyCount: ^u32, pProperties: [^]SparseImageFormatProperties2)
ProcGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV :: #type proc "system" (physicalDevice: PhysicalDevice, pCombinationCount: ^u32, pCombinations: [^]FramebufferMixedSamplesCombinationNV) -> Result
ProcGetPhysicalDeviceSurfaceCapabilities2EXT                        :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: [^]SurfaceCapabilities2EXT) -> Result
ProcGetPhysicalDeviceSurfaceCapabilities2KHR                        :: #type proc "system" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceCapabilities: [^]SurfaceCapabilities2KHR) -> Result
ProcGetPhysicalDeviceSurfaceCapabilitiesKHR                         :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceCapabilities: [^]SurfaceCapabilitiesKHR) -> Result
ProcGetPhysicalDeviceSurfaceFormats2KHR                             :: #type proc "system" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: [^]SurfaceFormat2KHR) -> Result
ProcGetPhysicalDeviceSurfaceFormatsKHR                              :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pSurfaceFormatCount: ^u32, pSurfaceFormats: [^]SurfaceFormatKHR) -> Result
ProcGetPhysicalDeviceSurfacePresentModes2EXT                        :: #type proc "system" (physicalDevice: PhysicalDevice, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pPresentModeCount: ^u32, pPresentModes: [^]PresentModeKHR) -> Result
ProcGetPhysicalDeviceSurfacePresentModesKHR                         :: #type proc "system" (physicalDevice: PhysicalDevice, surface: SurfaceKHR, pPresentModeCount: ^u32, pPresentModes: [^]PresentModeKHR) -> Result
ProcGetPhysicalDeviceSurfaceSupportKHR                              :: #type proc "system" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, surface: SurfaceKHR, pSupported: ^b32) -> Result
ProcGetPhysicalDeviceToolProperties                                 :: #type proc "system" (physicalDevice: PhysicalDevice, pToolCount: ^u32, pToolProperties: [^]PhysicalDeviceToolProperties) -> Result
ProcGetPhysicalDeviceToolPropertiesEXT                              :: #type proc "system" (physicalDevice: PhysicalDevice, pToolCount: ^u32, pToolProperties: [^]PhysicalDeviceToolProperties) -> Result
ProcGetPhysicalDeviceVideoCapabilitiesKHR                           :: #type proc "system" (physicalDevice: PhysicalDevice, pVideoProfile: ^VideoProfileInfoKHR, pCapabilities: [^]VideoCapabilitiesKHR) -> Result
ProcGetPhysicalDeviceVideoFormatPropertiesKHR                       :: #type proc "system" (physicalDevice: PhysicalDevice, pVideoFormatInfo: ^PhysicalDeviceVideoFormatInfoKHR, pVideoFormatPropertyCount: ^u32, pVideoFormatProperties: [^]VideoFormatPropertiesKHR) -> Result
ProcGetPhysicalDeviceWaylandPresentationSupportKHR                  :: #type proc "system" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32, display: ^wl_display) -> b32
ProcGetPhysicalDeviceWin32PresentationSupportKHR                    :: #type proc "system" (physicalDevice: PhysicalDevice, queueFamilyIndex: u32) -> b32
ProcGetWinrtDisplayNV                                               :: #type proc "system" (physicalDevice: PhysicalDevice, deviceRelativeId: u32, pDisplay: ^DisplayKHR) -> Result
ProcReleaseDisplayEXT                                               :: #type proc "system" (physicalDevice: PhysicalDevice, display: DisplayKHR) -> Result
ProcSubmitDebugUtilsMessageEXT                                      :: #type proc "system" (instance: Instance, messageSeverity: DebugUtilsMessageSeverityFlagsEXT, messageTypes: DebugUtilsMessageTypeFlagsEXT, pCallbackData: ^DebugUtilsMessengerCallbackDataEXT)

// Device Procedure Types
ProcAcquireFullScreenExclusiveModeEXT                      :: #type proc "system" (device: Device, swapchain: SwapchainKHR) -> Result
ProcAcquireNextImage2KHR                                   :: #type proc "system" (device: Device, pAcquireInfo: ^AcquireNextImageInfoKHR, pImageIndex: ^u32) -> Result
ProcAcquireNextImageKHR                                    :: #type proc "system" (device: Device, swapchain: SwapchainKHR, timeout: u64, semaphore: Semaphore, fence: Fence, pImageIndex: ^u32) -> Result
ProcAcquirePerformanceConfigurationINTEL                   :: #type proc "system" (device: Device, pAcquireInfo: ^PerformanceConfigurationAcquireInfoINTEL, pConfiguration: ^PerformanceConfigurationINTEL) -> Result
ProcAcquireProfilingLockKHR                                :: #type proc "system" (device: Device, pInfo: ^AcquireProfilingLockInfoKHR) -> Result
ProcAllocateCommandBuffers                                 :: #type proc "system" (device: Device, pAllocateInfo: ^CommandBufferAllocateInfo, pCommandBuffers: [^]CommandBuffer) -> Result
ProcAllocateDescriptorSets                                 :: #type proc "system" (device: Device, pAllocateInfo: ^DescriptorSetAllocateInfo, pDescriptorSets: [^]DescriptorSet) -> Result
ProcAllocateMemory                                         :: #type proc "system" (device: Device, pAllocateInfo: ^MemoryAllocateInfo, pAllocator: ^AllocationCallbacks, pMemory: ^DeviceMemory) -> Result
ProcBeginCommandBuffer                                     :: #type proc "system" (commandBuffer: CommandBuffer, pBeginInfo: ^CommandBufferBeginInfo) -> Result
ProcBindAccelerationStructureMemoryNV                      :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindAccelerationStructureMemoryInfoNV) -> Result
ProcBindBufferMemory                                       :: #type proc "system" (device: Device, buffer: Buffer, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
ProcBindBufferMemory2                                      :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindBufferMemoryInfo) -> Result
ProcBindBufferMemory2KHR                                   :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindBufferMemoryInfo) -> Result
ProcBindImageMemory                                        :: #type proc "system" (device: Device, image: Image, memory: DeviceMemory, memoryOffset: DeviceSize) -> Result
ProcBindImageMemory2                                       :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindImageMemoryInfo) -> Result
ProcBindImageMemory2KHR                                    :: #type proc "system" (device: Device, bindInfoCount: u32, pBindInfos: [^]BindImageMemoryInfo) -> Result
ProcBindOpticalFlowSessionImageNV                          :: #type proc "system" (device: Device, session: OpticalFlowSessionNV, bindingPoint: OpticalFlowSessionBindingPointNV, view: ImageView, layout: ImageLayout) -> Result
ProcBindVideoSessionMemoryKHR                              :: #type proc "system" (device: Device, videoSession: VideoSessionKHR, bindSessionMemoryInfoCount: u32, pBindSessionMemoryInfos: [^]BindVideoSessionMemoryInfoKHR) -> Result
ProcBuildAccelerationStructuresKHR                         :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, infoCount: u32, pInfos: [^]AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^[^]AccelerationStructureBuildRangeInfoKHR) -> Result
ProcBuildMicromapsEXT                                      :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, infoCount: u32, pInfos: [^]MicromapBuildInfoEXT) -> Result
ProcCmdBeginConditionalRenderingEXT                        :: #type proc "system" (commandBuffer: CommandBuffer, pConditionalRenderingBegin: ^ConditionalRenderingBeginInfoEXT)
ProcCmdBeginDebugUtilsLabelEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
ProcCmdBeginQuery                                          :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags)
ProcCmdBeginQueryIndexedEXT                                :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, flags: QueryControlFlags, index: u32)
ProcCmdBeginRenderPass                                     :: #type proc "system" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, contents: SubpassContents)
ProcCmdBeginRenderPass2                                    :: #type proc "system" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
ProcCmdBeginRenderPass2KHR                                 :: #type proc "system" (commandBuffer: CommandBuffer, pRenderPassBegin: ^RenderPassBeginInfo, pSubpassBeginInfo: ^SubpassBeginInfo)
ProcCmdBeginRendering                                      :: #type proc "system" (commandBuffer: CommandBuffer, pRenderingInfo: ^RenderingInfo)
ProcCmdBeginRenderingKHR                                   :: #type proc "system" (commandBuffer: CommandBuffer, pRenderingInfo: ^RenderingInfo)
ProcCmdBeginTransformFeedbackEXT                           :: #type proc "system" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: [^]Buffer, pCounterBufferOffsets: [^]DeviceSize)
ProcCmdBeginVideoCodingKHR                                 :: #type proc "system" (commandBuffer: CommandBuffer, pBeginInfo: ^VideoBeginCodingInfoKHR)
ProcCmdBindDescriptorBufferEmbeddedSamplersEXT             :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, set: u32)
ProcCmdBindDescriptorBuffersEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, bufferCount: u32, pBindingInfos: [^]DescriptorBufferBindingInfoEXT)
ProcCmdBindDescriptorSets                                  :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, firstSet: u32, descriptorSetCount: u32, pDescriptorSets: [^]DescriptorSet, dynamicOffsetCount: u32, pDynamicOffsets: [^]u32)
ProcCmdBindIndexBuffer                                     :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, indexType: IndexType)
ProcCmdBindInvocationMaskHUAWEI                            :: #type proc "system" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
ProcCmdBindPipeline                                        :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline)
ProcCmdBindPipelineShaderGroupNV                           :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, pipeline: Pipeline, groupIndex: u32)
ProcCmdBindShadersEXT                                      :: #type proc "system" (commandBuffer: CommandBuffer, stageCount: u32, pStages: [^]ShaderStageFlags, pShaders: [^]ShaderEXT)
ProcCmdBindShadingRateImageNV                              :: #type proc "system" (commandBuffer: CommandBuffer, imageView: ImageView, imageLayout: ImageLayout)
ProcCmdBindTransformFeedbackBuffersEXT                     :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize, pSizes: [^]DeviceSize)
ProcCmdBindVertexBuffers                                   :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize)
ProcCmdBindVertexBuffers2                                  :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize, pSizes: [^]DeviceSize, pStrides: [^]DeviceSize)
ProcCmdBindVertexBuffers2EXT                               :: #type proc "system" (commandBuffer: CommandBuffer, firstBinding: u32, bindingCount: u32, pBuffers: [^]Buffer, pOffsets: [^]DeviceSize, pSizes: [^]DeviceSize, pStrides: [^]DeviceSize)
ProcCmdBlitImage                                           :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]ImageBlit, filter: Filter)
ProcCmdBlitImage2                                          :: #type proc "system" (commandBuffer: CommandBuffer, pBlitImageInfo: ^BlitImageInfo2)
ProcCmdBlitImage2KHR                                       :: #type proc "system" (commandBuffer: CommandBuffer, pBlitImageInfo: ^BlitImageInfo2)
ProcCmdBuildAccelerationStructureNV                        :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^AccelerationStructureInfoNV, instanceData: Buffer, instanceOffset: DeviceSize, update: b32, dst: AccelerationStructureNV, src: AccelerationStructureNV, scratch: Buffer, scratchOffset: DeviceSize)
ProcCmdBuildAccelerationStructuresIndirectKHR              :: #type proc "system" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: [^]AccelerationStructureBuildGeometryInfoKHR, pIndirectDeviceAddresses: [^]DeviceAddress, pIndirectStrides: [^]u32, ppMaxPrimitiveCounts: ^[^]u32)
ProcCmdBuildAccelerationStructuresKHR                      :: #type proc "system" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: [^]AccelerationStructureBuildGeometryInfoKHR, ppBuildRangeInfos: ^[^]AccelerationStructureBuildRangeInfoKHR)
ProcCmdBuildMicromapsEXT                                   :: #type proc "system" (commandBuffer: CommandBuffer, infoCount: u32, pInfos: [^]MicromapBuildInfoEXT)
ProcCmdClearAttachments                                    :: #type proc "system" (commandBuffer: CommandBuffer, attachmentCount: u32, pAttachments: [^]ClearAttachment, rectCount: u32, pRects: [^]ClearRect)
ProcCmdClearColorImage                                     :: #type proc "system" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pColor: ^ClearColorValue, rangeCount: u32, pRanges: [^]ImageSubresourceRange)
ProcCmdClearDepthStencilImage                              :: #type proc "system" (commandBuffer: CommandBuffer, image: Image, imageLayout: ImageLayout, pDepthStencil: ^ClearDepthStencilValue, rangeCount: u32, pRanges: [^]ImageSubresourceRange)
ProcCmdControlVideoCodingKHR                               :: #type proc "system" (commandBuffer: CommandBuffer, pCodingControlInfo: ^VideoCodingControlInfoKHR)
ProcCmdCopyAccelerationStructureKHR                        :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureInfoKHR)
ProcCmdCopyAccelerationStructureNV                         :: #type proc "system" (commandBuffer: CommandBuffer, dst: AccelerationStructureNV, src: AccelerationStructureNV, mode: CopyAccelerationStructureModeKHR)
ProcCmdCopyAccelerationStructureToMemoryKHR                :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR)
ProcCmdCopyBuffer                                          :: #type proc "system" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstBuffer: Buffer, regionCount: u32, pRegions: [^]BufferCopy)
ProcCmdCopyBuffer2                                         :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferInfo: ^CopyBufferInfo2)
ProcCmdCopyBuffer2KHR                                      :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferInfo: ^CopyBufferInfo2)
ProcCmdCopyBufferToImage                                   :: #type proc "system" (commandBuffer: CommandBuffer, srcBuffer: Buffer, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]BufferImageCopy)
ProcCmdCopyBufferToImage2                                  :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferToImageInfo: ^CopyBufferToImageInfo2)
ProcCmdCopyBufferToImage2KHR                               :: #type proc "system" (commandBuffer: CommandBuffer, pCopyBufferToImageInfo: ^CopyBufferToImageInfo2)
ProcCmdCopyImage                                           :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]ImageCopy)
ProcCmdCopyImage2                                          :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageInfo: ^CopyImageInfo2)
ProcCmdCopyImage2KHR                                       :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageInfo: ^CopyImageInfo2)
ProcCmdCopyImageToBuffer                                   :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstBuffer: Buffer, regionCount: u32, pRegions: [^]BufferImageCopy)
ProcCmdCopyImageToBuffer2                                  :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageToBufferInfo: ^CopyImageToBufferInfo2)
ProcCmdCopyImageToBuffer2KHR                               :: #type proc "system" (commandBuffer: CommandBuffer, pCopyImageToBufferInfo: ^CopyImageToBufferInfo2)
ProcCmdCopyMemoryIndirectNV                                :: #type proc "system" (commandBuffer: CommandBuffer, copyBufferAddress: DeviceAddress, copyCount: u32, stride: u32)
ProcCmdCopyMemoryToAccelerationStructureKHR                :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR)
ProcCmdCopyMemoryToImageIndirectNV                         :: #type proc "system" (commandBuffer: CommandBuffer, copyBufferAddress: DeviceAddress, copyCount: u32, stride: u32, dstImage: Image, dstImageLayout: ImageLayout, pImageSubresources: [^]ImageSubresourceLayers)
ProcCmdCopyMemoryToMicromapEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyMemoryToMicromapInfoEXT)
ProcCmdCopyMicromapEXT                                     :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyMicromapInfoEXT)
ProcCmdCopyMicromapToMemoryEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, pInfo: ^CopyMicromapToMemoryInfoEXT)
ProcCmdCopyQueryPoolResults                                :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dstBuffer: Buffer, dstOffset: DeviceSize, stride: DeviceSize, flags: QueryResultFlags)
ProcCmdCuLaunchKernelNVX                                   :: #type proc "system" (commandBuffer: CommandBuffer, pLaunchInfo: ^CuLaunchInfoNVX)
ProcCmdDebugMarkerBeginEXT                                 :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
ProcCmdDebugMarkerEndEXT                                   :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdDebugMarkerInsertEXT                                :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^DebugMarkerMarkerInfoEXT)
ProcCmdDecodeVideoKHR                                      :: #type proc "system" (commandBuffer: CommandBuffer, pDecodeInfo: ^VideoDecodeInfoKHR)
ProcCmdDecompressMemoryIndirectCountNV                     :: #type proc "system" (commandBuffer: CommandBuffer, indirectCommandsAddress: DeviceAddress, indirectCommandsCountAddress: DeviceAddress, stride: u32)
ProcCmdDecompressMemoryNV                                  :: #type proc "system" (commandBuffer: CommandBuffer, decompressRegionCount: u32, pDecompressMemoryRegions: [^]DecompressMemoryRegionNV)
ProcCmdDispatch                                            :: #type proc "system" (commandBuffer: CommandBuffer, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDispatchBase                                        :: #type proc "system" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDispatchBaseKHR                                     :: #type proc "system" (commandBuffer: CommandBuffer, baseGroupX: u32, baseGroupY: u32, baseGroupZ: u32, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDispatchIndirect                                    :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize)
ProcCmdDraw                                                :: #type proc "system" (commandBuffer: CommandBuffer, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32)
ProcCmdDrawClusterHUAWEI                                   :: #type proc "system" (commandBuffer: CommandBuffer, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDrawClusterIndirectHUAWEI                           :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize)
ProcCmdDrawIndexed                                         :: #type proc "system" (commandBuffer: CommandBuffer, indexCount: u32, instanceCount: u32, firstIndex: u32, vertexOffset: i32, firstInstance: u32)
ProcCmdDrawIndexedIndirect                                 :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
ProcCmdDrawIndexedIndirectCount                            :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndexedIndirectCountAMD                         :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndexedIndirectCountKHR                         :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndirect                                        :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
ProcCmdDrawIndirectByteCountEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, instanceCount: u32, firstInstance: u32, counterBuffer: Buffer, counterBufferOffset: DeviceSize, counterOffset: u32, vertexStride: u32)
ProcCmdDrawIndirectCount                                   :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndirectCountAMD                                :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawIndirectCountKHR                                :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawMeshTasksEXT                                    :: #type proc "system" (commandBuffer: CommandBuffer, groupCountX: u32, groupCountY: u32, groupCountZ: u32)
ProcCmdDrawMeshTasksIndirectCountEXT                       :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawMeshTasksIndirectCountNV                        :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, countBuffer: Buffer, countBufferOffset: DeviceSize, maxDrawCount: u32, stride: u32)
ProcCmdDrawMeshTasksIndirectEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
ProcCmdDrawMeshTasksIndirectNV                             :: #type proc "system" (commandBuffer: CommandBuffer, buffer: Buffer, offset: DeviceSize, drawCount: u32, stride: u32)
ProcCmdDrawMeshTasksNV                                     :: #type proc "system" (commandBuffer: CommandBuffer, taskCount: u32, firstTask: u32)
ProcCmdDrawMultiEXT                                        :: #type proc "system" (commandBuffer: CommandBuffer, drawCount: u32, pVertexInfo: ^MultiDrawInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32)
ProcCmdDrawMultiIndexedEXT                                 :: #type proc "system" (commandBuffer: CommandBuffer, drawCount: u32, pIndexInfo: ^MultiDrawIndexedInfoEXT, instanceCount: u32, firstInstance: u32, stride: u32, pVertexOffset: ^i32)
ProcCmdEndConditionalRenderingEXT                          :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndDebugUtilsLabelEXT                               :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndQuery                                            :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32)
ProcCmdEndQueryIndexedEXT                                  :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, query: u32, index: u32)
ProcCmdEndRenderPass                                       :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndRenderPass2                                      :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdEndRenderPass2KHR                                   :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdEndRendering                                        :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndRenderingKHR                                     :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdEndTransformFeedbackEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, firstCounterBuffer: u32, counterBufferCount: u32, pCounterBuffers: [^]Buffer, pCounterBufferOffsets: [^]DeviceSize)
ProcCmdEndVideoCodingKHR                                   :: #type proc "system" (commandBuffer: CommandBuffer, pEndCodingInfo: ^VideoEndCodingInfoKHR)
ProcCmdExecuteCommands                                     :: #type proc "system" (commandBuffer: CommandBuffer, commandBufferCount: u32, pCommandBuffers: [^]CommandBuffer)
ProcCmdExecuteGeneratedCommandsNV                          :: #type proc "system" (commandBuffer: CommandBuffer, isPreprocessed: b32, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
ProcCmdFillBuffer                                          :: #type proc "system" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, size: DeviceSize, data: u32)
ProcCmdInsertDebugUtilsLabelEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, pLabelInfo: ^DebugUtilsLabelEXT)
ProcCmdNextSubpass                                         :: #type proc "system" (commandBuffer: CommandBuffer, contents: SubpassContents)
ProcCmdNextSubpass2                                        :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdNextSubpass2KHR                                     :: #type proc "system" (commandBuffer: CommandBuffer, pSubpassBeginInfo: ^SubpassBeginInfo, pSubpassEndInfo: ^SubpassEndInfo)
ProcCmdOpticalFlowExecuteNV                                :: #type proc "system" (commandBuffer: CommandBuffer, session: OpticalFlowSessionNV, pExecuteInfo: ^OpticalFlowExecuteInfoNV)
ProcCmdPipelineBarrier                                     :: #type proc "system" (commandBuffer: CommandBuffer, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, dependencyFlags: DependencyFlags, memoryBarrierCount: u32, pMemoryBarriers: [^]MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: [^]BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: [^]ImageMemoryBarrier)
ProcCmdPipelineBarrier2                                    :: #type proc "system" (commandBuffer: CommandBuffer, pDependencyInfo: ^DependencyInfo)
ProcCmdPipelineBarrier2KHR                                 :: #type proc "system" (commandBuffer: CommandBuffer, pDependencyInfo: ^DependencyInfo)
ProcCmdPreprocessGeneratedCommandsNV                       :: #type proc "system" (commandBuffer: CommandBuffer, pGeneratedCommandsInfo: ^GeneratedCommandsInfoNV)
ProcCmdPushConstants                                       :: #type proc "system" (commandBuffer: CommandBuffer, layout: PipelineLayout, stageFlags: ShaderStageFlags, offset: u32, size: u32, pValues: rawptr)
ProcCmdPushDescriptorSetKHR                                :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, set: u32, descriptorWriteCount: u32, pDescriptorWrites: [^]WriteDescriptorSet)
ProcCmdPushDescriptorSetWithTemplateKHR                    :: #type proc "system" (commandBuffer: CommandBuffer, descriptorUpdateTemplate: DescriptorUpdateTemplate, layout: PipelineLayout, set: u32, pData: rawptr)
ProcCmdResetEvent                                          :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
ProcCmdResetEvent2                                         :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags2)
ProcCmdResetEvent2KHR                                      :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags2)
ProcCmdResetQueryPool                                      :: #type proc "system" (commandBuffer: CommandBuffer, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
ProcCmdResolveImage                                        :: #type proc "system" (commandBuffer: CommandBuffer, srcImage: Image, srcImageLayout: ImageLayout, dstImage: Image, dstImageLayout: ImageLayout, regionCount: u32, pRegions: [^]ImageResolve)
ProcCmdResolveImage2                                       :: #type proc "system" (commandBuffer: CommandBuffer, pResolveImageInfo: ^ResolveImageInfo2)
ProcCmdResolveImage2KHR                                    :: #type proc "system" (commandBuffer: CommandBuffer, pResolveImageInfo: ^ResolveImageInfo2)
ProcCmdSetAlphaToCoverageEnableEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, alphaToCoverageEnable: b32)
ProcCmdSetAlphaToOneEnableEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, alphaToOneEnable: b32)
ProcCmdSetAttachmentFeedbackLoopEnableEXT                  :: #type proc "system" (commandBuffer: CommandBuffer, aspectMask: ImageAspectFlags)
ProcCmdSetBlendConstants                                   :: #type proc "system" (commandBuffer: CommandBuffer, blendConstants: ^[4]f32)
ProcCmdSetCheckpointNV                                     :: #type proc "system" (commandBuffer: CommandBuffer, pCheckpointMarker: rawptr)
ProcCmdSetCoarseSampleOrderNV                              :: #type proc "system" (commandBuffer: CommandBuffer, sampleOrderType: CoarseSampleOrderTypeNV, customSampleOrderCount: u32, pCustomSampleOrders: [^]CoarseSampleOrderCustomNV)
ProcCmdSetColorBlendAdvancedEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, firstAttachment: u32, attachmentCount: u32, pColorBlendAdvanced: ^ColorBlendAdvancedEXT)
ProcCmdSetColorBlendEnableEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, firstAttachment: u32, attachmentCount: u32, pColorBlendEnables: [^]b32)
ProcCmdSetColorBlendEquationEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, firstAttachment: u32, attachmentCount: u32, pColorBlendEquations: [^]ColorBlendEquationEXT)
ProcCmdSetColorWriteMaskEXT                                :: #type proc "system" (commandBuffer: CommandBuffer, firstAttachment: u32, attachmentCount: u32, pColorWriteMasks: [^]ColorComponentFlags)
ProcCmdSetConservativeRasterizationModeEXT                 :: #type proc "system" (commandBuffer: CommandBuffer, conservativeRasterizationMode: ConservativeRasterizationModeEXT)
ProcCmdSetCoverageModulationModeNV                         :: #type proc "system" (commandBuffer: CommandBuffer, coverageModulationMode: CoverageModulationModeNV)
ProcCmdSetCoverageModulationTableEnableNV                  :: #type proc "system" (commandBuffer: CommandBuffer, coverageModulationTableEnable: b32)
ProcCmdSetCoverageModulationTableNV                        :: #type proc "system" (commandBuffer: CommandBuffer, coverageModulationTableCount: u32, pCoverageModulationTable: [^]f32)
ProcCmdSetCoverageReductionModeNV                          :: #type proc "system" (commandBuffer: CommandBuffer, coverageReductionMode: CoverageReductionModeNV)
ProcCmdSetCoverageToColorEnableNV                          :: #type proc "system" (commandBuffer: CommandBuffer, coverageToColorEnable: b32)
ProcCmdSetCoverageToColorLocationNV                        :: #type proc "system" (commandBuffer: CommandBuffer, coverageToColorLocation: u32)
ProcCmdSetCullMode                                         :: #type proc "system" (commandBuffer: CommandBuffer, cullMode: CullModeFlags)
ProcCmdSetCullModeEXT                                      :: #type proc "system" (commandBuffer: CommandBuffer, cullMode: CullModeFlags)
ProcCmdSetDepthBias                                        :: #type proc "system" (commandBuffer: CommandBuffer, depthBiasConstantFactor: f32, depthBiasClamp: f32, depthBiasSlopeFactor: f32)
ProcCmdSetDepthBiasEnable                                  :: #type proc "system" (commandBuffer: CommandBuffer, depthBiasEnable: b32)
ProcCmdSetDepthBiasEnableEXT                               :: #type proc "system" (commandBuffer: CommandBuffer, depthBiasEnable: b32)
ProcCmdSetDepthBounds                                      :: #type proc "system" (commandBuffer: CommandBuffer, minDepthBounds: f32, maxDepthBounds: f32)
ProcCmdSetDepthBoundsTestEnable                            :: #type proc "system" (commandBuffer: CommandBuffer, depthBoundsTestEnable: b32)
ProcCmdSetDepthBoundsTestEnableEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, depthBoundsTestEnable: b32)
ProcCmdSetDepthClampEnableEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, depthClampEnable: b32)
ProcCmdSetDepthClipEnableEXT                               :: #type proc "system" (commandBuffer: CommandBuffer, depthClipEnable: b32)
ProcCmdSetDepthClipNegativeOneToOneEXT                     :: #type proc "system" (commandBuffer: CommandBuffer, negativeOneToOne: b32)
ProcCmdSetDepthCompareOp                                   :: #type proc "system" (commandBuffer: CommandBuffer, depthCompareOp: CompareOp)
ProcCmdSetDepthCompareOpEXT                                :: #type proc "system" (commandBuffer: CommandBuffer, depthCompareOp: CompareOp)
ProcCmdSetDepthTestEnable                                  :: #type proc "system" (commandBuffer: CommandBuffer, depthTestEnable: b32)
ProcCmdSetDepthTestEnableEXT                               :: #type proc "system" (commandBuffer: CommandBuffer, depthTestEnable: b32)
ProcCmdSetDepthWriteEnable                                 :: #type proc "system" (commandBuffer: CommandBuffer, depthWriteEnable: b32)
ProcCmdSetDepthWriteEnableEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, depthWriteEnable: b32)
ProcCmdSetDescriptorBufferOffsetsEXT                       :: #type proc "system" (commandBuffer: CommandBuffer, pipelineBindPoint: PipelineBindPoint, layout: PipelineLayout, firstSet: u32, setCount: u32, pBufferIndices: [^]u32, pOffsets: [^]DeviceSize)
ProcCmdSetDeviceMask                                       :: #type proc "system" (commandBuffer: CommandBuffer, deviceMask: u32)
ProcCmdSetDeviceMaskKHR                                    :: #type proc "system" (commandBuffer: CommandBuffer, deviceMask: u32)
ProcCmdSetDiscardRectangleEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, firstDiscardRectangle: u32, discardRectangleCount: u32, pDiscardRectangles: [^]Rect2D)
ProcCmdSetDiscardRectangleEnableEXT                        :: #type proc "system" (commandBuffer: CommandBuffer, discardRectangleEnable: b32)
ProcCmdSetDiscardRectangleModeEXT                          :: #type proc "system" (commandBuffer: CommandBuffer, discardRectangleMode: DiscardRectangleModeEXT)
ProcCmdSetEvent                                            :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, stageMask: PipelineStageFlags)
ProcCmdSetEvent2                                           :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, pDependencyInfo: ^DependencyInfo)
ProcCmdSetEvent2KHR                                        :: #type proc "system" (commandBuffer: CommandBuffer, event: Event, pDependencyInfo: ^DependencyInfo)
ProcCmdSetExclusiveScissorEnableNV                         :: #type proc "system" (commandBuffer: CommandBuffer, firstExclusiveScissor: u32, exclusiveScissorCount: u32, pExclusiveScissorEnables: [^]b32)
ProcCmdSetExclusiveScissorNV                               :: #type proc "system" (commandBuffer: CommandBuffer, firstExclusiveScissor: u32, exclusiveScissorCount: u32, pExclusiveScissors: [^]Rect2D)
ProcCmdSetExtraPrimitiveOverestimationSizeEXT              :: #type proc "system" (commandBuffer: CommandBuffer, extraPrimitiveOverestimationSize: f32)
ProcCmdSetFragmentShadingRateEnumNV                        :: #type proc "system" (commandBuffer: CommandBuffer, shadingRate: FragmentShadingRateNV, combinerOps: ^[2]FragmentShadingRateCombinerOpKHR)
ProcCmdSetFragmentShadingRateKHR                           :: #type proc "system" (commandBuffer: CommandBuffer, pFragmentSize: ^Extent2D, combinerOps: ^[2]FragmentShadingRateCombinerOpKHR)
ProcCmdSetFrontFace                                        :: #type proc "system" (commandBuffer: CommandBuffer, frontFace: FrontFace)
ProcCmdSetFrontFaceEXT                                     :: #type proc "system" (commandBuffer: CommandBuffer, frontFace: FrontFace)
ProcCmdSetLineRasterizationModeEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, lineRasterizationMode: LineRasterizationModeEXT)
ProcCmdSetLineStippleEXT                                   :: #type proc "system" (commandBuffer: CommandBuffer, lineStippleFactor: u32, lineStipplePattern: u16)
ProcCmdSetLineStippleEnableEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, stippledLineEnable: b32)
ProcCmdSetLineWidth                                        :: #type proc "system" (commandBuffer: CommandBuffer, lineWidth: f32)
ProcCmdSetLogicOpEXT                                       :: #type proc "system" (commandBuffer: CommandBuffer, logicOp: LogicOp)
ProcCmdSetLogicOpEnableEXT                                 :: #type proc "system" (commandBuffer: CommandBuffer, logicOpEnable: b32)
ProcCmdSetPatchControlPointsEXT                            :: #type proc "system" (commandBuffer: CommandBuffer, patchControlPoints: u32)
ProcCmdSetPerformanceMarkerINTEL                           :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceMarkerInfoINTEL) -> Result
ProcCmdSetPerformanceOverrideINTEL                         :: #type proc "system" (commandBuffer: CommandBuffer, pOverrideInfo: ^PerformanceOverrideInfoINTEL) -> Result
ProcCmdSetPerformanceStreamMarkerINTEL                     :: #type proc "system" (commandBuffer: CommandBuffer, pMarkerInfo: ^PerformanceStreamMarkerInfoINTEL) -> Result
ProcCmdSetPolygonModeEXT                                   :: #type proc "system" (commandBuffer: CommandBuffer, polygonMode: PolygonMode)
ProcCmdSetPrimitiveRestartEnable                           :: #type proc "system" (commandBuffer: CommandBuffer, primitiveRestartEnable: b32)
ProcCmdSetPrimitiveRestartEnableEXT                        :: #type proc "system" (commandBuffer: CommandBuffer, primitiveRestartEnable: b32)
ProcCmdSetPrimitiveTopology                                :: #type proc "system" (commandBuffer: CommandBuffer, primitiveTopology: PrimitiveTopology)
ProcCmdSetPrimitiveTopologyEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, primitiveTopology: PrimitiveTopology)
ProcCmdSetProvokingVertexModeEXT                           :: #type proc "system" (commandBuffer: CommandBuffer, provokingVertexMode: ProvokingVertexModeEXT)
ProcCmdSetRasterizationSamplesEXT                          :: #type proc "system" (commandBuffer: CommandBuffer, rasterizationSamples: SampleCountFlags)
ProcCmdSetRasterizationStreamEXT                           :: #type proc "system" (commandBuffer: CommandBuffer, rasterizationStream: u32)
ProcCmdSetRasterizerDiscardEnable                          :: #type proc "system" (commandBuffer: CommandBuffer, rasterizerDiscardEnable: b32)
ProcCmdSetRasterizerDiscardEnableEXT                       :: #type proc "system" (commandBuffer: CommandBuffer, rasterizerDiscardEnable: b32)
ProcCmdSetRayTracingPipelineStackSizeKHR                   :: #type proc "system" (commandBuffer: CommandBuffer, pipelineStackSize: u32)
ProcCmdSetRepresentativeFragmentTestEnableNV               :: #type proc "system" (commandBuffer: CommandBuffer, representativeFragmentTestEnable: b32)
ProcCmdSetSampleLocationsEXT                               :: #type proc "system" (commandBuffer: CommandBuffer, pSampleLocationsInfo: ^SampleLocationsInfoEXT)
ProcCmdSetSampleLocationsEnableEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, sampleLocationsEnable: b32)
ProcCmdSetSampleMaskEXT                                    :: #type proc "system" (commandBuffer: CommandBuffer, samples: SampleCountFlags, pSampleMask: ^SampleMask)
ProcCmdSetScissor                                          :: #type proc "system" (commandBuffer: CommandBuffer, firstScissor: u32, scissorCount: u32, pScissors: [^]Rect2D)
ProcCmdSetScissorWithCount                                 :: #type proc "system" (commandBuffer: CommandBuffer, scissorCount: u32, pScissors: [^]Rect2D)
ProcCmdSetScissorWithCountEXT                              :: #type proc "system" (commandBuffer: CommandBuffer, scissorCount: u32, pScissors: [^]Rect2D)
ProcCmdSetShadingRateImageEnableNV                         :: #type proc "system" (commandBuffer: CommandBuffer, shadingRateImageEnable: b32)
ProcCmdSetStencilCompareMask                               :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, compareMask: u32)
ProcCmdSetStencilOp                                        :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, failOp: StencilOp, passOp: StencilOp, depthFailOp: StencilOp, compareOp: CompareOp)
ProcCmdSetStencilOpEXT                                     :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, failOp: StencilOp, passOp: StencilOp, depthFailOp: StencilOp, compareOp: CompareOp)
ProcCmdSetStencilReference                                 :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, reference: u32)
ProcCmdSetStencilTestEnable                                :: #type proc "system" (commandBuffer: CommandBuffer, stencilTestEnable: b32)
ProcCmdSetStencilTestEnableEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, stencilTestEnable: b32)
ProcCmdSetStencilWriteMask                                 :: #type proc "system" (commandBuffer: CommandBuffer, faceMask: StencilFaceFlags, writeMask: u32)
ProcCmdSetTessellationDomainOriginEXT                      :: #type proc "system" (commandBuffer: CommandBuffer, domainOrigin: TessellationDomainOrigin)
ProcCmdSetVertexInputEXT                                   :: #type proc "system" (commandBuffer: CommandBuffer, vertexBindingDescriptionCount: u32, pVertexBindingDescriptions: [^]VertexInputBindingDescription2EXT, vertexAttributeDescriptionCount: u32, pVertexAttributeDescriptions: [^]VertexInputAttributeDescription2EXT)
ProcCmdSetViewport                                         :: #type proc "system" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewports: [^]Viewport)
ProcCmdSetViewportShadingRatePaletteNV                     :: #type proc "system" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pShadingRatePalettes: [^]ShadingRatePaletteNV)
ProcCmdSetViewportSwizzleNV                                :: #type proc "system" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewportSwizzles: [^]ViewportSwizzleNV)
ProcCmdSetViewportWScalingEnableNV                         :: #type proc "system" (commandBuffer: CommandBuffer, viewportWScalingEnable: b32)
ProcCmdSetViewportWScalingNV                               :: #type proc "system" (commandBuffer: CommandBuffer, firstViewport: u32, viewportCount: u32, pViewportWScalings: [^]ViewportWScalingNV)
ProcCmdSetViewportWithCount                                :: #type proc "system" (commandBuffer: CommandBuffer, viewportCount: u32, pViewports: [^]Viewport)
ProcCmdSetViewportWithCountEXT                             :: #type proc "system" (commandBuffer: CommandBuffer, viewportCount: u32, pViewports: [^]Viewport)
ProcCmdSubpassShadingHUAWEI                                :: #type proc "system" (commandBuffer: CommandBuffer)
ProcCmdTraceRaysIndirect2KHR                               :: #type proc "system" (commandBuffer: CommandBuffer, indirectDeviceAddress: DeviceAddress)
ProcCmdTraceRaysIndirectKHR                                :: #type proc "system" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pMissShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pHitShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: [^]StridedDeviceAddressRegionKHR, indirectDeviceAddress: DeviceAddress)
ProcCmdTraceRaysKHR                                        :: #type proc "system" (commandBuffer: CommandBuffer, pRaygenShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pMissShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pHitShaderBindingTable: [^]StridedDeviceAddressRegionKHR, pCallableShaderBindingTable: [^]StridedDeviceAddressRegionKHR, width: u32, height: u32, depth: u32)
ProcCmdTraceRaysNV                                         :: #type proc "system" (commandBuffer: CommandBuffer, raygenShaderBindingTableBuffer: Buffer, raygenShaderBindingOffset: DeviceSize, missShaderBindingTableBuffer: Buffer, missShaderBindingOffset: DeviceSize, missShaderBindingStride: DeviceSize, hitShaderBindingTableBuffer: Buffer, hitShaderBindingOffset: DeviceSize, hitShaderBindingStride: DeviceSize, callableShaderBindingTableBuffer: Buffer, callableShaderBindingOffset: DeviceSize, callableShaderBindingStride: DeviceSize, width: u32, height: u32, depth: u32)
ProcCmdUpdateBuffer                                        :: #type proc "system" (commandBuffer: CommandBuffer, dstBuffer: Buffer, dstOffset: DeviceSize, dataSize: DeviceSize, pData: rawptr)
ProcCmdWaitEvents                                          :: #type proc "system" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: [^]Event, srcStageMask: PipelineStageFlags, dstStageMask: PipelineStageFlags, memoryBarrierCount: u32, pMemoryBarriers: [^]MemoryBarrier, bufferMemoryBarrierCount: u32, pBufferMemoryBarriers: [^]BufferMemoryBarrier, imageMemoryBarrierCount: u32, pImageMemoryBarriers: [^]ImageMemoryBarrier)
ProcCmdWaitEvents2                                         :: #type proc "system" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: [^]Event, pDependencyInfos: [^]DependencyInfo)
ProcCmdWaitEvents2KHR                                      :: #type proc "system" (commandBuffer: CommandBuffer, eventCount: u32, pEvents: [^]Event, pDependencyInfos: [^]DependencyInfo)
ProcCmdWriteAccelerationStructuresPropertiesKHR            :: #type proc "system" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: [^]AccelerationStructureKHR, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
ProcCmdWriteAccelerationStructuresPropertiesNV             :: #type proc "system" (commandBuffer: CommandBuffer, accelerationStructureCount: u32, pAccelerationStructures: [^]AccelerationStructureNV, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
ProcCmdWriteBufferMarker2AMD                               :: #type proc "system" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
ProcCmdWriteBufferMarkerAMD                                :: #type proc "system" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, dstBuffer: Buffer, dstOffset: DeviceSize, marker: u32)
ProcCmdWriteMicromapsPropertiesEXT                         :: #type proc "system" (commandBuffer: CommandBuffer, micromapCount: u32, pMicromaps: [^]MicromapEXT, queryType: QueryType, queryPool: QueryPool, firstQuery: u32)
ProcCmdWriteTimestamp                                      :: #type proc "system" (commandBuffer: CommandBuffer, pipelineStage: PipelineStageFlags, queryPool: QueryPool, query: u32)
ProcCmdWriteTimestamp2                                     :: #type proc "system" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2, queryPool: QueryPool, query: u32)
ProcCmdWriteTimestamp2KHR                                  :: #type proc "system" (commandBuffer: CommandBuffer, stage: PipelineStageFlags2, queryPool: QueryPool, query: u32)
ProcCompileDeferredNV                                      :: #type proc "system" (device: Device, pipeline: Pipeline, shader: u32) -> Result
ProcCopyAccelerationStructureKHR                           :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureInfoKHR) -> Result
ProcCopyAccelerationStructureToMemoryKHR                   :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyAccelerationStructureToMemoryInfoKHR) -> Result
ProcCopyMemoryToAccelerationStructureKHR                   :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyMemoryToAccelerationStructureInfoKHR) -> Result
ProcCopyMemoryToMicromapEXT                                :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyMemoryToMicromapInfoEXT) -> Result
ProcCopyMicromapEXT                                        :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyMicromapInfoEXT) -> Result
ProcCopyMicromapToMemoryEXT                                :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pInfo: ^CopyMicromapToMemoryInfoEXT) -> Result
ProcCreateAccelerationStructureKHR                         :: #type proc "system" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoKHR, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureKHR) -> Result
ProcCreateAccelerationStructureNV                          :: #type proc "system" (device: Device, pCreateInfo: ^AccelerationStructureCreateInfoNV, pAllocator: ^AllocationCallbacks, pAccelerationStructure: ^AccelerationStructureNV) -> Result
ProcCreateBuffer                                           :: #type proc "system" (device: Device, pCreateInfo: ^BufferCreateInfo, pAllocator: ^AllocationCallbacks, pBuffer: ^Buffer) -> Result
ProcCreateBufferView                                       :: #type proc "system" (device: Device, pCreateInfo: ^BufferViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^BufferView) -> Result
ProcCreateCommandPool                                      :: #type proc "system" (device: Device, pCreateInfo: ^CommandPoolCreateInfo, pAllocator: ^AllocationCallbacks, pCommandPool: ^CommandPool) -> Result
ProcCreateComputePipelines                                 :: #type proc "system" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]ComputePipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateCuFunctionNVX                                    :: #type proc "system" (device: Device, pCreateInfo: ^CuFunctionCreateInfoNVX, pAllocator: ^AllocationCallbacks, pFunction: ^CuFunctionNVX) -> Result
ProcCreateCuModuleNVX                                      :: #type proc "system" (device: Device, pCreateInfo: ^CuModuleCreateInfoNVX, pAllocator: ^AllocationCallbacks, pModule: ^CuModuleNVX) -> Result
ProcCreateDeferredOperationKHR                             :: #type proc "system" (device: Device, pAllocator: ^AllocationCallbacks, pDeferredOperation: ^DeferredOperationKHR) -> Result
ProcCreateDescriptorPool                                   :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorPoolCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorPool: ^DescriptorPool) -> Result
ProcCreateDescriptorSetLayout                              :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pSetLayout: ^DescriptorSetLayout) -> Result
ProcCreateDescriptorUpdateTemplate                         :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
ProcCreateDescriptorUpdateTemplateKHR                      :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorUpdateTemplateCreateInfo, pAllocator: ^AllocationCallbacks, pDescriptorUpdateTemplate: ^DescriptorUpdateTemplate) -> Result
ProcCreateEvent                                            :: #type proc "system" (device: Device, pCreateInfo: ^EventCreateInfo, pAllocator: ^AllocationCallbacks, pEvent: ^Event) -> Result
ProcCreateFence                                            :: #type proc "system" (device: Device, pCreateInfo: ^FenceCreateInfo, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
ProcCreateFramebuffer                                      :: #type proc "system" (device: Device, pCreateInfo: ^FramebufferCreateInfo, pAllocator: ^AllocationCallbacks, pFramebuffer: ^Framebuffer) -> Result
ProcCreateGraphicsPipelines                                :: #type proc "system" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]GraphicsPipelineCreateInfo, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateImage                                            :: #type proc "system" (device: Device, pCreateInfo: ^ImageCreateInfo, pAllocator: ^AllocationCallbacks, pImage: ^Image) -> Result
ProcCreateImageView                                        :: #type proc "system" (device: Device, pCreateInfo: ^ImageViewCreateInfo, pAllocator: ^AllocationCallbacks, pView: ^ImageView) -> Result
ProcCreateIndirectCommandsLayoutNV                         :: #type proc "system" (device: Device, pCreateInfo: ^IndirectCommandsLayoutCreateInfoNV, pAllocator: ^AllocationCallbacks, pIndirectCommandsLayout: ^IndirectCommandsLayoutNV) -> Result
ProcCreateMicromapEXT                                      :: #type proc "system" (device: Device, pCreateInfo: ^MicromapCreateInfoEXT, pAllocator: ^AllocationCallbacks, pMicromap: ^MicromapEXT) -> Result
ProcCreateOpticalFlowSessionNV                             :: #type proc "system" (device: Device, pCreateInfo: ^OpticalFlowSessionCreateInfoNV, pAllocator: ^AllocationCallbacks, pSession: ^OpticalFlowSessionNV) -> Result
ProcCreatePipelineCache                                    :: #type proc "system" (device: Device, pCreateInfo: ^PipelineCacheCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineCache: ^PipelineCache) -> Result
ProcCreatePipelineLayout                                   :: #type proc "system" (device: Device, pCreateInfo: ^PipelineLayoutCreateInfo, pAllocator: ^AllocationCallbacks, pPipelineLayout: ^PipelineLayout) -> Result
ProcCreatePrivateDataSlot                                  :: #type proc "system" (device: Device, pCreateInfo: ^PrivateDataSlotCreateInfo, pAllocator: ^AllocationCallbacks, pPrivateDataSlot: ^PrivateDataSlot) -> Result
ProcCreatePrivateDataSlotEXT                               :: #type proc "system" (device: Device, pCreateInfo: ^PrivateDataSlotCreateInfo, pAllocator: ^AllocationCallbacks, pPrivateDataSlot: ^PrivateDataSlot) -> Result
ProcCreateQueryPool                                        :: #type proc "system" (device: Device, pCreateInfo: ^QueryPoolCreateInfo, pAllocator: ^AllocationCallbacks, pQueryPool: ^QueryPool) -> Result
ProcCreateRayTracingPipelinesKHR                           :: #type proc "system" (device: Device, deferredOperation: DeferredOperationKHR, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]RayTracingPipelineCreateInfoKHR, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateRayTracingPipelinesNV                            :: #type proc "system" (device: Device, pipelineCache: PipelineCache, createInfoCount: u32, pCreateInfos: [^]RayTracingPipelineCreateInfoNV, pAllocator: ^AllocationCallbacks, pPipelines: [^]Pipeline) -> Result
ProcCreateRenderPass                                       :: #type proc "system" (device: Device, pCreateInfo: ^RenderPassCreateInfo, pAllocator: ^AllocationCallbacks, pRenderPass: [^]RenderPass) -> Result
ProcCreateRenderPass2                                      :: #type proc "system" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: [^]RenderPass) -> Result
ProcCreateRenderPass2KHR                                   :: #type proc "system" (device: Device, pCreateInfo: ^RenderPassCreateInfo2, pAllocator: ^AllocationCallbacks, pRenderPass: [^]RenderPass) -> Result
ProcCreateSampler                                          :: #type proc "system" (device: Device, pCreateInfo: ^SamplerCreateInfo, pAllocator: ^AllocationCallbacks, pSampler: ^Sampler) -> Result
ProcCreateSamplerYcbcrConversion                           :: #type proc "system" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
ProcCreateSamplerYcbcrConversionKHR                        :: #type proc "system" (device: Device, pCreateInfo: ^SamplerYcbcrConversionCreateInfo, pAllocator: ^AllocationCallbacks, pYcbcrConversion: ^SamplerYcbcrConversion) -> Result
ProcCreateSemaphore                                        :: #type proc "system" (device: Device, pCreateInfo: ^SemaphoreCreateInfo, pAllocator: ^AllocationCallbacks, pSemaphore: ^Semaphore) -> Result
ProcCreateShaderModule                                     :: #type proc "system" (device: Device, pCreateInfo: ^ShaderModuleCreateInfo, pAllocator: ^AllocationCallbacks, pShaderModule: ^ShaderModule) -> Result
ProcCreateShadersEXT                                       :: #type proc "system" (device: Device, createInfoCount: u32, pCreateInfos: [^]ShaderCreateInfoEXT, pAllocator: ^AllocationCallbacks, pShaders: [^]ShaderEXT) -> Result
ProcCreateSharedSwapchainsKHR                              :: #type proc "system" (device: Device, swapchainCount: u32, pCreateInfos: [^]SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchains: [^]SwapchainKHR) -> Result
ProcCreateSwapchainKHR                                     :: #type proc "system" (device: Device, pCreateInfo: ^SwapchainCreateInfoKHR, pAllocator: ^AllocationCallbacks, pSwapchain: ^SwapchainKHR) -> Result
ProcCreateValidationCacheEXT                               :: #type proc "system" (device: Device, pCreateInfo: ^ValidationCacheCreateInfoEXT, pAllocator: ^AllocationCallbacks, pValidationCache: ^ValidationCacheEXT) -> Result
ProcCreateVideoSessionKHR                                  :: #type proc "system" (device: Device, pCreateInfo: ^VideoSessionCreateInfoKHR, pAllocator: ^AllocationCallbacks, pVideoSession: ^VideoSessionKHR) -> Result
ProcCreateVideoSessionParametersKHR                        :: #type proc "system" (device: Device, pCreateInfo: ^VideoSessionParametersCreateInfoKHR, pAllocator: ^AllocationCallbacks, pVideoSessionParameters: [^]VideoSessionParametersKHR) -> Result
ProcDebugMarkerSetObjectNameEXT                            :: #type proc "system" (device: Device, pNameInfo: ^DebugMarkerObjectNameInfoEXT) -> Result
ProcDebugMarkerSetObjectTagEXT                             :: #type proc "system" (device: Device, pTagInfo: ^DebugMarkerObjectTagInfoEXT) -> Result
ProcDeferredOperationJoinKHR                               :: #type proc "system" (device: Device, operation: DeferredOperationKHR) -> Result
ProcDestroyAccelerationStructureKHR                        :: #type proc "system" (device: Device, accelerationStructure: AccelerationStructureKHR, pAllocator: ^AllocationCallbacks)
ProcDestroyAccelerationStructureNV                         :: #type proc "system" (device: Device, accelerationStructure: AccelerationStructureNV, pAllocator: ^AllocationCallbacks)
ProcDestroyBuffer                                          :: #type proc "system" (device: Device, buffer: Buffer, pAllocator: ^AllocationCallbacks)
ProcDestroyBufferView                                      :: #type proc "system" (device: Device, bufferView: BufferView, pAllocator: ^AllocationCallbacks)
ProcDestroyCommandPool                                     :: #type proc "system" (device: Device, commandPool: CommandPool, pAllocator: ^AllocationCallbacks)
ProcDestroyCuFunctionNVX                                   :: #type proc "system" (device: Device, function: CuFunctionNVX, pAllocator: ^AllocationCallbacks)
ProcDestroyCuModuleNVX                                     :: #type proc "system" (device: Device, module: CuModuleNVX, pAllocator: ^AllocationCallbacks)
ProcDestroyDeferredOperationKHR                            :: #type proc "system" (device: Device, operation: DeferredOperationKHR, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorPool                                  :: #type proc "system" (device: Device, descriptorPool: DescriptorPool, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorSetLayout                             :: #type proc "system" (device: Device, descriptorSetLayout: DescriptorSetLayout, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorUpdateTemplate                        :: #type proc "system" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
ProcDestroyDescriptorUpdateTemplateKHR                     :: #type proc "system" (device: Device, descriptorUpdateTemplate: DescriptorUpdateTemplate, pAllocator: ^AllocationCallbacks)
ProcDestroyDevice                                          :: #type proc "system" (device: Device, pAllocator: ^AllocationCallbacks)
ProcDestroyEvent                                           :: #type proc "system" (device: Device, event: Event, pAllocator: ^AllocationCallbacks)
ProcDestroyFence                                           :: #type proc "system" (device: Device, fence: Fence, pAllocator: ^AllocationCallbacks)
ProcDestroyFramebuffer                                     :: #type proc "system" (device: Device, framebuffer: Framebuffer, pAllocator: ^AllocationCallbacks)
ProcDestroyImage                                           :: #type proc "system" (device: Device, image: Image, pAllocator: ^AllocationCallbacks)
ProcDestroyImageView                                       :: #type proc "system" (device: Device, imageView: ImageView, pAllocator: ^AllocationCallbacks)
ProcDestroyIndirectCommandsLayoutNV                        :: #type proc "system" (device: Device, indirectCommandsLayout: IndirectCommandsLayoutNV, pAllocator: ^AllocationCallbacks)
ProcDestroyMicromapEXT                                     :: #type proc "system" (device: Device, micromap: MicromapEXT, pAllocator: ^AllocationCallbacks)
ProcDestroyOpticalFlowSessionNV                            :: #type proc "system" (device: Device, session: OpticalFlowSessionNV, pAllocator: ^AllocationCallbacks)
ProcDestroyPipeline                                        :: #type proc "system" (device: Device, pipeline: Pipeline, pAllocator: ^AllocationCallbacks)
ProcDestroyPipelineCache                                   :: #type proc "system" (device: Device, pipelineCache: PipelineCache, pAllocator: ^AllocationCallbacks)
ProcDestroyPipelineLayout                                  :: #type proc "system" (device: Device, pipelineLayout: PipelineLayout, pAllocator: ^AllocationCallbacks)
ProcDestroyPrivateDataSlot                                 :: #type proc "system" (device: Device, privateDataSlot: PrivateDataSlot, pAllocator: ^AllocationCallbacks)
ProcDestroyPrivateDataSlotEXT                              :: #type proc "system" (device: Device, privateDataSlot: PrivateDataSlot, pAllocator: ^AllocationCallbacks)
ProcDestroyQueryPool                                       :: #type proc "system" (device: Device, queryPool: QueryPool, pAllocator: ^AllocationCallbacks)
ProcDestroyRenderPass                                      :: #type proc "system" (device: Device, renderPass: RenderPass, pAllocator: ^AllocationCallbacks)
ProcDestroySampler                                         :: #type proc "system" (device: Device, sampler: Sampler, pAllocator: ^AllocationCallbacks)
ProcDestroySamplerYcbcrConversion                          :: #type proc "system" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
ProcDestroySamplerYcbcrConversionKHR                       :: #type proc "system" (device: Device, ycbcrConversion: SamplerYcbcrConversion, pAllocator: ^AllocationCallbacks)
ProcDestroySemaphore                                       :: #type proc "system" (device: Device, semaphore: Semaphore, pAllocator: ^AllocationCallbacks)
ProcDestroyShaderEXT                                       :: #type proc "system" (device: Device, shader: ShaderEXT, pAllocator: ^AllocationCallbacks)
ProcDestroyShaderModule                                    :: #type proc "system" (device: Device, shaderModule: ShaderModule, pAllocator: ^AllocationCallbacks)
ProcDestroySwapchainKHR                                    :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pAllocator: ^AllocationCallbacks)
ProcDestroyValidationCacheEXT                              :: #type proc "system" (device: Device, validationCache: ValidationCacheEXT, pAllocator: ^AllocationCallbacks)
ProcDestroyVideoSessionKHR                                 :: #type proc "system" (device: Device, videoSession: VideoSessionKHR, pAllocator: ^AllocationCallbacks)
ProcDestroyVideoSessionParametersKHR                       :: #type proc "system" (device: Device, videoSessionParameters: VideoSessionParametersKHR, pAllocator: ^AllocationCallbacks)
ProcDeviceWaitIdle                                         :: #type proc "system" (device: Device) -> Result
ProcDisplayPowerControlEXT                                 :: #type proc "system" (device: Device, display: DisplayKHR, pDisplayPowerInfo: ^DisplayPowerInfoEXT) -> Result
ProcEndCommandBuffer                                       :: #type proc "system" (commandBuffer: CommandBuffer) -> Result
ProcExportMetalObjectsEXT                                  :: #type proc "system" (device: Device, pMetalObjectsInfo: ^ExportMetalObjectsInfoEXT)
ProcFlushMappedMemoryRanges                                :: #type proc "system" (device: Device, memoryRangeCount: u32, pMemoryRanges: [^]MappedMemoryRange) -> Result
ProcFreeCommandBuffers                                     :: #type proc "system" (device: Device, commandPool: CommandPool, commandBufferCount: u32, pCommandBuffers: [^]CommandBuffer)
ProcFreeDescriptorSets                                     :: #type proc "system" (device: Device, descriptorPool: DescriptorPool, descriptorSetCount: u32, pDescriptorSets: [^]DescriptorSet) -> Result
ProcFreeMemory                                             :: #type proc "system" (device: Device, memory: DeviceMemory, pAllocator: ^AllocationCallbacks)
ProcGetAccelerationStructureBuildSizesKHR                  :: #type proc "system" (device: Device, buildType: AccelerationStructureBuildTypeKHR, pBuildInfo: ^AccelerationStructureBuildGeometryInfoKHR, pMaxPrimitiveCounts: [^]u32, pSizeInfo: ^AccelerationStructureBuildSizesInfoKHR)
ProcGetAccelerationStructureDeviceAddressKHR               :: #type proc "system" (device: Device, pInfo: ^AccelerationStructureDeviceAddressInfoKHR) -> DeviceAddress
ProcGetAccelerationStructureHandleNV                       :: #type proc "system" (device: Device, accelerationStructure: AccelerationStructureNV, dataSize: int, pData: rawptr) -> Result
ProcGetAccelerationStructureMemoryRequirementsNV           :: #type proc "system" (device: Device, pInfo: ^AccelerationStructureMemoryRequirementsInfoNV, pMemoryRequirements: [^]MemoryRequirements2KHR)
ProcGetAccelerationStructureOpaqueCaptureDescriptorDataEXT :: #type proc "system" (device: Device, pInfo: ^AccelerationStructureCaptureDescriptorDataInfoEXT, pData: rawptr) -> Result
ProcGetBufferDeviceAddress                                 :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
ProcGetBufferDeviceAddressEXT                              :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
ProcGetBufferDeviceAddressKHR                              :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> DeviceAddress
ProcGetBufferMemoryRequirements                            :: #type proc "system" (device: Device, buffer: Buffer, pMemoryRequirements: [^]MemoryRequirements)
ProcGetBufferMemoryRequirements2                           :: #type proc "system" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetBufferMemoryRequirements2KHR                        :: #type proc "system" (device: Device, pInfo: ^BufferMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetBufferOpaqueCaptureAddress                          :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
ProcGetBufferOpaqueCaptureAddressKHR                       :: #type proc "system" (device: Device, pInfo: ^BufferDeviceAddressInfo) -> u64
ProcGetBufferOpaqueCaptureDescriptorDataEXT                :: #type proc "system" (device: Device, pInfo: ^BufferCaptureDescriptorDataInfoEXT, pData: rawptr) -> Result
ProcGetCalibratedTimestampsEXT                             :: #type proc "system" (device: Device, timestampCount: u32, pTimestampInfos: [^]CalibratedTimestampInfoEXT, pTimestamps: [^]u64, pMaxDeviation: ^u64) -> Result
ProcGetDeferredOperationMaxConcurrencyKHR                  :: #type proc "system" (device: Device, operation: DeferredOperationKHR) -> u32
ProcGetDeferredOperationResultKHR                          :: #type proc "system" (device: Device, operation: DeferredOperationKHR) -> Result
ProcGetDescriptorEXT                                       :: #type proc "system" (device: Device, pDescriptorInfo: ^DescriptorGetInfoEXT, dataSize: int, pDescriptor: rawptr)
ProcGetDescriptorSetHostMappingVALVE                       :: #type proc "system" (device: Device, descriptorSet: DescriptorSet, ppData: ^rawptr)
ProcGetDescriptorSetLayoutBindingOffsetEXT                 :: #type proc "system" (device: Device, layout: DescriptorSetLayout, binding: u32, pOffset: ^DeviceSize)
ProcGetDescriptorSetLayoutHostMappingInfoVALVE             :: #type proc "system" (device: Device, pBindingReference: ^DescriptorSetBindingReferenceVALVE, pHostMapping: ^DescriptorSetLayoutHostMappingInfoVALVE)
ProcGetDescriptorSetLayoutSizeEXT                          :: #type proc "system" (device: Device, layout: DescriptorSetLayout, pLayoutSizeInBytes: [^]DeviceSize)
ProcGetDescriptorSetLayoutSupport                          :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
ProcGetDescriptorSetLayoutSupportKHR                       :: #type proc "system" (device: Device, pCreateInfo: ^DescriptorSetLayoutCreateInfo, pSupport: ^DescriptorSetLayoutSupport)
ProcGetDeviceAccelerationStructureCompatibilityKHR         :: #type proc "system" (device: Device, pVersionInfo: ^AccelerationStructureVersionInfoKHR, pCompatibility: ^AccelerationStructureCompatibilityKHR)
ProcGetDeviceBufferMemoryRequirements                      :: #type proc "system" (device: Device, pInfo: ^DeviceBufferMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceBufferMemoryRequirementsKHR                   :: #type proc "system" (device: Device, pInfo: ^DeviceBufferMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceFaultInfoEXT                                  :: #type proc "system" (device: Device, pFaultCounts: [^]DeviceFaultCountsEXT, pFaultInfo: ^DeviceFaultInfoEXT) -> Result
ProcGetDeviceGroupPeerMemoryFeatures                       :: #type proc "system" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: [^]PeerMemoryFeatureFlags)
ProcGetDeviceGroupPeerMemoryFeaturesKHR                    :: #type proc "system" (device: Device, heapIndex: u32, localDeviceIndex: u32, remoteDeviceIndex: u32, pPeerMemoryFeatures: [^]PeerMemoryFeatureFlags)
ProcGetDeviceGroupPresentCapabilitiesKHR                   :: #type proc "system" (device: Device, pDeviceGroupPresentCapabilities: [^]DeviceGroupPresentCapabilitiesKHR) -> Result
ProcGetDeviceGroupSurfacePresentModes2EXT                  :: #type proc "system" (device: Device, pSurfaceInfo: ^PhysicalDeviceSurfaceInfo2KHR, pModes: [^]DeviceGroupPresentModeFlagsKHR) -> Result
ProcGetDeviceGroupSurfacePresentModesKHR                   :: #type proc "system" (device: Device, surface: SurfaceKHR, pModes: [^]DeviceGroupPresentModeFlagsKHR) -> Result
ProcGetDeviceImageMemoryRequirements                       :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceImageMemoryRequirementsKHR                    :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetDeviceImageSparseMemoryRequirements                 :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetDeviceImageSparseMemoryRequirementsKHR              :: #type proc "system" (device: Device, pInfo: ^DeviceImageMemoryRequirements, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetDeviceMemoryCommitment                              :: #type proc "system" (device: Device, memory: DeviceMemory, pCommittedMemoryInBytes: [^]DeviceSize)
ProcGetDeviceMemoryOpaqueCaptureAddress                    :: #type proc "system" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
ProcGetDeviceMemoryOpaqueCaptureAddressKHR                 :: #type proc "system" (device: Device, pInfo: ^DeviceMemoryOpaqueCaptureAddressInfo) -> u64
ProcGetDeviceMicromapCompatibilityEXT                      :: #type proc "system" (device: Device, pVersionInfo: ^MicromapVersionInfoEXT, pCompatibility: ^AccelerationStructureCompatibilityKHR)
ProcGetDeviceProcAddr                                      :: #type proc "system" (device: Device, pName: cstring) -> ProcVoidFunction
ProcGetDeviceQueue                                         :: #type proc "system" (device: Device, queueFamilyIndex: u32, queueIndex: u32, pQueue: ^Queue)
ProcGetDeviceQueue2                                        :: #type proc "system" (device: Device, pQueueInfo: ^DeviceQueueInfo2, pQueue: ^Queue)
ProcGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI          :: #type proc "system" (device: Device, renderpass: RenderPass, pMaxWorkgroupSize: ^Extent2D) -> Result
ProcGetDynamicRenderingTilePropertiesQCOM                  :: #type proc "system" (device: Device, pRenderingInfo: ^RenderingInfo, pProperties: [^]TilePropertiesQCOM) -> Result
ProcGetEventStatus                                         :: #type proc "system" (device: Device, event: Event) -> Result
ProcGetFenceFdKHR                                          :: #type proc "system" (device: Device, pGetFdInfo: ^FenceGetFdInfoKHR, pFd: ^c.int) -> Result
ProcGetFenceStatus                                         :: #type proc "system" (device: Device, fence: Fence) -> Result
ProcGetFenceWin32HandleKHR                                 :: #type proc "system" (device: Device, pGetWin32HandleInfo: ^FenceGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
ProcGetFramebufferTilePropertiesQCOM                       :: #type proc "system" (device: Device, framebuffer: Framebuffer, pPropertiesCount: ^u32, pProperties: [^]TilePropertiesQCOM) -> Result
ProcGetGeneratedCommandsMemoryRequirementsNV               :: #type proc "system" (device: Device, pInfo: ^GeneratedCommandsMemoryRequirementsInfoNV, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetImageDrmFormatModifierPropertiesEXT                 :: #type proc "system" (device: Device, image: Image, pProperties: [^]ImageDrmFormatModifierPropertiesEXT) -> Result
ProcGetImageMemoryRequirements                             :: #type proc "system" (device: Device, image: Image, pMemoryRequirements: [^]MemoryRequirements)
ProcGetImageMemoryRequirements2                            :: #type proc "system" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetImageMemoryRequirements2KHR                         :: #type proc "system" (device: Device, pInfo: ^ImageMemoryRequirementsInfo2, pMemoryRequirements: [^]MemoryRequirements2)
ProcGetImageOpaqueCaptureDescriptorDataEXT                 :: #type proc "system" (device: Device, pInfo: ^ImageCaptureDescriptorDataInfoEXT, pData: rawptr) -> Result
ProcGetImageSparseMemoryRequirements                       :: #type proc "system" (device: Device, image: Image, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements)
ProcGetImageSparseMemoryRequirements2                      :: #type proc "system" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetImageSparseMemoryRequirements2KHR                   :: #type proc "system" (device: Device, pInfo: ^ImageSparseMemoryRequirementsInfo2, pSparseMemoryRequirementCount: ^u32, pSparseMemoryRequirements: [^]SparseImageMemoryRequirements2)
ProcGetImageSubresourceLayout                              :: #type proc "system" (device: Device, image: Image, pSubresource: ^ImageSubresource, pLayout: ^SubresourceLayout)
ProcGetImageSubresourceLayout2EXT                          :: #type proc "system" (device: Device, image: Image, pSubresource: ^ImageSubresource2EXT, pLayout: ^SubresourceLayout2EXT)
ProcGetImageViewAddressNVX                                 :: #type proc "system" (device: Device, imageView: ImageView, pProperties: [^]ImageViewAddressPropertiesNVX) -> Result
ProcGetImageViewHandleNVX                                  :: #type proc "system" (device: Device, pInfo: ^ImageViewHandleInfoNVX) -> u32
ProcGetImageViewOpaqueCaptureDescriptorDataEXT             :: #type proc "system" (device: Device, pInfo: ^ImageViewCaptureDescriptorDataInfoEXT, pData: rawptr) -> Result
ProcGetMemoryFdKHR                                         :: #type proc "system" (device: Device, pGetFdInfo: ^MemoryGetFdInfoKHR, pFd: ^c.int) -> Result
ProcGetMemoryFdPropertiesKHR                               :: #type proc "system" (device: Device, handleType: ExternalMemoryHandleTypeFlags, fd: c.int, pMemoryFdProperties: [^]MemoryFdPropertiesKHR) -> Result
ProcGetMemoryHostPointerPropertiesEXT                      :: #type proc "system" (device: Device, handleType: ExternalMemoryHandleTypeFlags, pHostPointer: rawptr, pMemoryHostPointerProperties: [^]MemoryHostPointerPropertiesEXT) -> Result
ProcGetMemoryRemoteAddressNV                               :: #type proc "system" (device: Device, pMemoryGetRemoteAddressInfo: ^MemoryGetRemoteAddressInfoNV, pAddress: [^]RemoteAddressNV) -> Result
ProcGetMemoryWin32HandleKHR                                :: #type proc "system" (device: Device, pGetWin32HandleInfo: ^MemoryGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
ProcGetMemoryWin32HandleNV                                 :: #type proc "system" (device: Device, memory: DeviceMemory, handleType: ExternalMemoryHandleTypeFlagsNV, pHandle: ^HANDLE) -> Result
ProcGetMemoryWin32HandlePropertiesKHR                      :: #type proc "system" (device: Device, handleType: ExternalMemoryHandleTypeFlags, handle: HANDLE, pMemoryWin32HandleProperties: [^]MemoryWin32HandlePropertiesKHR) -> Result
ProcGetMicromapBuildSizesEXT                               :: #type proc "system" (device: Device, buildType: AccelerationStructureBuildTypeKHR, pBuildInfo: ^MicromapBuildInfoEXT, pSizeInfo: ^MicromapBuildSizesInfoEXT)
ProcGetPastPresentationTimingGOOGLE                        :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pPresentationTimingCount: ^u32, pPresentationTimings: [^]PastPresentationTimingGOOGLE) -> Result
ProcGetPerformanceParameterINTEL                           :: #type proc "system" (device: Device, parameter: PerformanceParameterTypeINTEL, pValue: ^PerformanceValueINTEL) -> Result
ProcGetPipelineCacheData                                   :: #type proc "system" (device: Device, pipelineCache: PipelineCache, pDataSize: ^int, pData: rawptr) -> Result
ProcGetPipelineExecutableInternalRepresentationsKHR        :: #type proc "system" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pInternalRepresentationCount: ^u32, pInternalRepresentations: [^]PipelineExecutableInternalRepresentationKHR) -> Result
ProcGetPipelineExecutablePropertiesKHR                     :: #type proc "system" (device: Device, pPipelineInfo: ^PipelineInfoKHR, pExecutableCount: ^u32, pProperties: [^]PipelineExecutablePropertiesKHR) -> Result
ProcGetPipelineExecutableStatisticsKHR                     :: #type proc "system" (device: Device, pExecutableInfo: ^PipelineExecutableInfoKHR, pStatisticCount: ^u32, pStatistics: [^]PipelineExecutableStatisticKHR) -> Result
ProcGetPipelinePropertiesEXT                               :: #type proc "system" (device: Device, pPipelineInfo: ^PipelineInfoEXT, pPipelineProperties: [^]BaseOutStructure) -> Result
ProcGetPrivateData                                         :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, pData: ^u64)
ProcGetPrivateDataEXT                                      :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, pData: ^u64)
ProcGetQueryPoolResults                                    :: #type proc "system" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32, dataSize: int, pData: rawptr, stride: DeviceSize, flags: QueryResultFlags) -> Result
ProcGetQueueCheckpointData2NV                              :: #type proc "system" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointData2NV)
ProcGetQueueCheckpointDataNV                               :: #type proc "system" (queue: Queue, pCheckpointDataCount: ^u32, pCheckpointData: ^CheckpointDataNV)
ProcGetRayTracingCaptureReplayShaderGroupHandlesKHR        :: #type proc "system" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
ProcGetRayTracingShaderGroupHandlesKHR                     :: #type proc "system" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
ProcGetRayTracingShaderGroupHandlesNV                      :: #type proc "system" (device: Device, pipeline: Pipeline, firstGroup: u32, groupCount: u32, dataSize: int, pData: rawptr) -> Result
ProcGetRayTracingShaderGroupStackSizeKHR                   :: #type proc "system" (device: Device, pipeline: Pipeline, group: u32, groupShader: ShaderGroupShaderKHR) -> DeviceSize
ProcGetRefreshCycleDurationGOOGLE                          :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pDisplayTimingProperties: [^]RefreshCycleDurationGOOGLE) -> Result
ProcGetRenderAreaGranularity                               :: #type proc "system" (device: Device, renderPass: RenderPass, pGranularity: ^Extent2D)
ProcGetSamplerOpaqueCaptureDescriptorDataEXT               :: #type proc "system" (device: Device, pInfo: ^SamplerCaptureDescriptorDataInfoEXT, pData: rawptr) -> Result
ProcGetSemaphoreCounterValue                               :: #type proc "system" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
ProcGetSemaphoreCounterValueKHR                            :: #type proc "system" (device: Device, semaphore: Semaphore, pValue: ^u64) -> Result
ProcGetSemaphoreFdKHR                                      :: #type proc "system" (device: Device, pGetFdInfo: ^SemaphoreGetFdInfoKHR, pFd: ^c.int) -> Result
ProcGetSemaphoreWin32HandleKHR                             :: #type proc "system" (device: Device, pGetWin32HandleInfo: ^SemaphoreGetWin32HandleInfoKHR, pHandle: ^HANDLE) -> Result
ProcGetShaderBinaryDataEXT                                 :: #type proc "system" (device: Device, shader: ShaderEXT, pDataSize: ^int, pData: rawptr) -> Result
ProcGetShaderInfoAMD                                       :: #type proc "system" (device: Device, pipeline: Pipeline, shaderStage: ShaderStageFlags, infoType: ShaderInfoTypeAMD, pInfoSize: ^int, pInfo: rawptr) -> Result
ProcGetShaderModuleCreateInfoIdentifierEXT                 :: #type proc "system" (device: Device, pCreateInfo: ^ShaderModuleCreateInfo, pIdentifier: ^ShaderModuleIdentifierEXT)
ProcGetShaderModuleIdentifierEXT                           :: #type proc "system" (device: Device, shaderModule: ShaderModule, pIdentifier: ^ShaderModuleIdentifierEXT)
ProcGetSwapchainCounterEXT                                 :: #type proc "system" (device: Device, swapchain: SwapchainKHR, counter: SurfaceCounterFlagsEXT, pCounterValue: ^u64) -> Result
ProcGetSwapchainImagesKHR                                  :: #type proc "system" (device: Device, swapchain: SwapchainKHR, pSwapchainImageCount: ^u32, pSwapchainImages: [^]Image) -> Result
ProcGetSwapchainStatusKHR                                  :: #type proc "system" (device: Device, swapchain: SwapchainKHR) -> Result
ProcGetValidationCacheDataEXT                              :: #type proc "system" (device: Device, validationCache: ValidationCacheEXT, pDataSize: ^int, pData: rawptr) -> Result
ProcGetVideoSessionMemoryRequirementsKHR                   :: #type proc "system" (device: Device, videoSession: VideoSessionKHR, pMemoryRequirementsCount: ^u32, pMemoryRequirements: [^]VideoSessionMemoryRequirementsKHR) -> Result
ProcImportFenceFdKHR                                       :: #type proc "system" (device: Device, pImportFenceFdInfo: ^ImportFenceFdInfoKHR) -> Result
ProcImportFenceWin32HandleKHR                              :: #type proc "system" (device: Device, pImportFenceWin32HandleInfo: ^ImportFenceWin32HandleInfoKHR) -> Result
ProcImportSemaphoreFdKHR                                   :: #type proc "system" (device: Device, pImportSemaphoreFdInfo: ^ImportSemaphoreFdInfoKHR) -> Result
ProcImportSemaphoreWin32HandleKHR                          :: #type proc "system" (device: Device, pImportSemaphoreWin32HandleInfo: ^ImportSemaphoreWin32HandleInfoKHR) -> Result
ProcInitializePerformanceApiINTEL                          :: #type proc "system" (device: Device, pInitializeInfo: ^InitializePerformanceApiInfoINTEL) -> Result
ProcInvalidateMappedMemoryRanges                           :: #type proc "system" (device: Device, memoryRangeCount: u32, pMemoryRanges: [^]MappedMemoryRange) -> Result
ProcMapMemory                                              :: #type proc "system" (device: Device, memory: DeviceMemory, offset: DeviceSize, size: DeviceSize, flags: MemoryMapFlags, ppData: ^rawptr) -> Result
ProcMapMemory2KHR                                          :: #type proc "system" (device: Device, pMemoryMapInfo: ^MemoryMapInfoKHR, ppData: ^rawptr) -> Result
ProcMergePipelineCaches                                    :: #type proc "system" (device: Device, dstCache: PipelineCache, srcCacheCount: u32, pSrcCaches: [^]PipelineCache) -> Result
ProcMergeValidationCachesEXT                               :: #type proc "system" (device: Device, dstCache: ValidationCacheEXT, srcCacheCount: u32, pSrcCaches: [^]ValidationCacheEXT) -> Result
ProcQueueBeginDebugUtilsLabelEXT                           :: #type proc "system" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
ProcQueueBindSparse                                        :: #type proc "system" (queue: Queue, bindInfoCount: u32, pBindInfo: ^BindSparseInfo, fence: Fence) -> Result
ProcQueueEndDebugUtilsLabelEXT                             :: #type proc "system" (queue: Queue)
ProcQueueInsertDebugUtilsLabelEXT                          :: #type proc "system" (queue: Queue, pLabelInfo: ^DebugUtilsLabelEXT)
ProcQueuePresentKHR                                        :: #type proc "system" (queue: Queue, pPresentInfo: ^PresentInfoKHR) -> Result
ProcQueueSetPerformanceConfigurationINTEL                  :: #type proc "system" (queue: Queue, configuration: PerformanceConfigurationINTEL) -> Result
ProcQueueSubmit                                            :: #type proc "system" (queue: Queue, submitCount: u32, pSubmits: [^]SubmitInfo, fence: Fence) -> Result
ProcQueueSubmit2                                           :: #type proc "system" (queue: Queue, submitCount: u32, pSubmits: [^]SubmitInfo2, fence: Fence) -> Result
ProcQueueSubmit2KHR                                        :: #type proc "system" (queue: Queue, submitCount: u32, pSubmits: [^]SubmitInfo2, fence: Fence) -> Result
ProcQueueWaitIdle                                          :: #type proc "system" (queue: Queue) -> Result
ProcRegisterDeviceEventEXT                                 :: #type proc "system" (device: Device, pDeviceEventInfo: ^DeviceEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
ProcRegisterDisplayEventEXT                                :: #type proc "system" (device: Device, display: DisplayKHR, pDisplayEventInfo: ^DisplayEventInfoEXT, pAllocator: ^AllocationCallbacks, pFence: ^Fence) -> Result
ProcReleaseFullScreenExclusiveModeEXT                      :: #type proc "system" (device: Device, swapchain: SwapchainKHR) -> Result
ProcReleasePerformanceConfigurationINTEL                   :: #type proc "system" (device: Device, configuration: PerformanceConfigurationINTEL) -> Result
ProcReleaseProfilingLockKHR                                :: #type proc "system" (device: Device)
ProcReleaseSwapchainImagesEXT                              :: #type proc "system" (device: Device, pReleaseInfo: ^ReleaseSwapchainImagesInfoEXT) -> Result
ProcResetCommandBuffer                                     :: #type proc "system" (commandBuffer: CommandBuffer, flags: CommandBufferResetFlags) -> Result
ProcResetCommandPool                                       :: #type proc "system" (device: Device, commandPool: CommandPool, flags: CommandPoolResetFlags) -> Result
ProcResetDescriptorPool                                    :: #type proc "system" (device: Device, descriptorPool: DescriptorPool, flags: DescriptorPoolResetFlags) -> Result
ProcResetEvent                                             :: #type proc "system" (device: Device, event: Event) -> Result
ProcResetFences                                            :: #type proc "system" (device: Device, fenceCount: u32, pFences: [^]Fence) -> Result
ProcResetQueryPool                                         :: #type proc "system" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
ProcResetQueryPoolEXT                                      :: #type proc "system" (device: Device, queryPool: QueryPool, firstQuery: u32, queryCount: u32)
ProcSetDebugUtilsObjectNameEXT                             :: #type proc "system" (device: Device, pNameInfo: ^DebugUtilsObjectNameInfoEXT) -> Result
ProcSetDebugUtilsObjectTagEXT                              :: #type proc "system" (device: Device, pTagInfo: ^DebugUtilsObjectTagInfoEXT) -> Result
ProcSetDeviceMemoryPriorityEXT                             :: #type proc "system" (device: Device, memory: DeviceMemory, priority: f32)
ProcSetEvent                                               :: #type proc "system" (device: Device, event: Event) -> Result
ProcSetHdrMetadataEXT                                      :: #type proc "system" (device: Device, swapchainCount: u32, pSwapchains: [^]SwapchainKHR, pMetadata: ^HdrMetadataEXT)
ProcSetLocalDimmingAMD                                     :: #type proc "system" (device: Device, swapChain: SwapchainKHR, localDimmingEnable: b32)
ProcSetPrivateData                                         :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, data: u64) -> Result
ProcSetPrivateDataEXT                                      :: #type proc "system" (device: Device, objectType: ObjectType, objectHandle: u64, privateDataSlot: PrivateDataSlot, data: u64) -> Result
ProcSignalSemaphore                                        :: #type proc "system" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
ProcSignalSemaphoreKHR                                     :: #type proc "system" (device: Device, pSignalInfo: ^SemaphoreSignalInfo) -> Result
ProcTrimCommandPool                                        :: #type proc "system" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
ProcTrimCommandPoolKHR                                     :: #type proc "system" (device: Device, commandPool: CommandPool, flags: CommandPoolTrimFlags)
ProcUninitializePerformanceApiINTEL                        :: #type proc "system" (device: Device)
ProcUnmapMemory                                            :: #type proc "system" (device: Device, memory: DeviceMemory)
ProcUnmapMemory2KHR                                        :: #type proc "system" (device: Device, pMemoryUnmapInfo: ^MemoryUnmapInfoKHR) -> Result
ProcUpdateDescriptorSetWithTemplate                        :: #type proc "system" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
ProcUpdateDescriptorSetWithTemplateKHR                     :: #type proc "system" (device: Device, descriptorSet: DescriptorSet, descriptorUpdateTemplate: DescriptorUpdateTemplate, pData: rawptr)
ProcUpdateDescriptorSets                                   :: #type proc "system" (device: Device, descriptorWriteCount: u32, pDescriptorWrites: [^]WriteDescriptorSet, descriptorCopyCount: u32, pDescriptorCopies: [^]CopyDescriptorSet)
ProcUpdateVideoSessionParametersKHR                        :: #type proc "system" (device: Device, videoSessionParameters: VideoSessionParametersKHR, pUpdateInfo: ^VideoSessionParametersUpdateInfoKHR) -> Result
ProcWaitForFences                                          :: #type proc "system" (device: Device, fenceCount: u32, pFences: [^]Fence, waitAll: b32, timeout: u64) -> Result
ProcWaitForPresentKHR                                      :: #type proc "system" (device: Device, swapchain: SwapchainKHR, presentId: u64, timeout: u64) -> Result
ProcWaitSemaphores                                         :: #type proc "system" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
ProcWaitSemaphoresKHR                                      :: #type proc "system" (device: Device, pWaitInfo: ^SemaphoreWaitInfo, timeout: u64) -> Result
ProcWriteAccelerationStructuresPropertiesKHR               :: #type proc "system" (device: Device, accelerationStructureCount: u32, pAccelerationStructures: [^]AccelerationStructureKHR, queryType: QueryType, dataSize: int, pData: rawptr, stride: int) -> Result
ProcWriteMicromapsPropertiesEXT                            :: #type proc "system" (device: Device, micromapCount: u32, pMicromaps: [^]MicromapEXT, queryType: QueryType, dataSize: int, pData: rawptr, stride: int) -> Result


// Loader Procedures
CreateInstance:                       ProcCreateInstance
DebugUtilsMessengerCallbackEXT:       ProcDebugUtilsMessengerCallbackEXT
DeviceMemoryReportCallbackEXT:        ProcDeviceMemoryReportCallbackEXT
EnumerateInstanceExtensionProperties: ProcEnumerateInstanceExtensionProperties
EnumerateInstanceLayerProperties:     ProcEnumerateInstanceLayerProperties
EnumerateInstanceVersion:             ProcEnumerateInstanceVersion
GetInstanceProcAddr:                  ProcGetInstanceProcAddr

// Instance Procedures
AcquireDrmDisplayEXT:                                            ProcAcquireDrmDisplayEXT
AcquireWinrtDisplayNV:                                           ProcAcquireWinrtDisplayNV
CreateDebugReportCallbackEXT:                                    ProcCreateDebugReportCallbackEXT
CreateDebugUtilsMessengerEXT:                                    ProcCreateDebugUtilsMessengerEXT
CreateDevice:                                                    ProcCreateDevice
CreateDisplayModeKHR:                                            ProcCreateDisplayModeKHR
CreateDisplayPlaneSurfaceKHR:                                    ProcCreateDisplayPlaneSurfaceKHR
CreateHeadlessSurfaceEXT:                                        ProcCreateHeadlessSurfaceEXT
CreateIOSSurfaceMVK:                                             ProcCreateIOSSurfaceMVK
CreateMacOSSurfaceMVK:                                           ProcCreateMacOSSurfaceMVK
CreateMetalSurfaceEXT:                                           ProcCreateMetalSurfaceEXT
CreateWaylandSurfaceKHR:                                         ProcCreateWaylandSurfaceKHR
CreateWin32SurfaceKHR:                                           ProcCreateWin32SurfaceKHR
DebugReportMessageEXT:                                           ProcDebugReportMessageEXT
DestroyDebugReportCallbackEXT:                                   ProcDestroyDebugReportCallbackEXT
DestroyDebugUtilsMessengerEXT:                                   ProcDestroyDebugUtilsMessengerEXT
DestroyInstance:                                                 ProcDestroyInstance
DestroySurfaceKHR:                                               ProcDestroySurfaceKHR
EnumerateDeviceExtensionProperties:                              ProcEnumerateDeviceExtensionProperties
EnumerateDeviceLayerProperties:                                  ProcEnumerateDeviceLayerProperties
EnumeratePhysicalDeviceGroups:                                   ProcEnumeratePhysicalDeviceGroups
EnumeratePhysicalDeviceGroupsKHR:                                ProcEnumeratePhysicalDeviceGroupsKHR
EnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR:   ProcEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR
EnumeratePhysicalDevices:                                        ProcEnumeratePhysicalDevices
GetDisplayModeProperties2KHR:                                    ProcGetDisplayModeProperties2KHR
GetDisplayModePropertiesKHR:                                     ProcGetDisplayModePropertiesKHR
GetDisplayPlaneCapabilities2KHR:                                 ProcGetDisplayPlaneCapabilities2KHR
GetDisplayPlaneCapabilitiesKHR:                                  ProcGetDisplayPlaneCapabilitiesKHR
GetDisplayPlaneSupportedDisplaysKHR:                             ProcGetDisplayPlaneSupportedDisplaysKHR
GetDrmDisplayEXT:                                                ProcGetDrmDisplayEXT
GetInstanceProcAddrLUNARG:                                       ProcGetInstanceProcAddrLUNARG
GetPhysicalDeviceCalibrateableTimeDomainsEXT:                    ProcGetPhysicalDeviceCalibrateableTimeDomainsEXT
GetPhysicalDeviceCooperativeMatrixPropertiesNV:                  ProcGetPhysicalDeviceCooperativeMatrixPropertiesNV
GetPhysicalDeviceDisplayPlaneProperties2KHR:                     ProcGetPhysicalDeviceDisplayPlaneProperties2KHR
GetPhysicalDeviceDisplayPlanePropertiesKHR:                      ProcGetPhysicalDeviceDisplayPlanePropertiesKHR
GetPhysicalDeviceDisplayProperties2KHR:                          ProcGetPhysicalDeviceDisplayProperties2KHR
GetPhysicalDeviceDisplayPropertiesKHR:                           ProcGetPhysicalDeviceDisplayPropertiesKHR
GetPhysicalDeviceExternalBufferProperties:                       ProcGetPhysicalDeviceExternalBufferProperties
GetPhysicalDeviceExternalBufferPropertiesKHR:                    ProcGetPhysicalDeviceExternalBufferPropertiesKHR
GetPhysicalDeviceExternalFenceProperties:                        ProcGetPhysicalDeviceExternalFenceProperties
GetPhysicalDeviceExternalFencePropertiesKHR:                     ProcGetPhysicalDeviceExternalFencePropertiesKHR
GetPhysicalDeviceExternalImageFormatPropertiesNV:                ProcGetPhysicalDeviceExternalImageFormatPropertiesNV
GetPhysicalDeviceExternalSemaphoreProperties:                    ProcGetPhysicalDeviceExternalSemaphoreProperties
GetPhysicalDeviceExternalSemaphorePropertiesKHR:                 ProcGetPhysicalDeviceExternalSemaphorePropertiesKHR
GetPhysicalDeviceFeatures:                                       ProcGetPhysicalDeviceFeatures
GetPhysicalDeviceFeatures2:                                      ProcGetPhysicalDeviceFeatures2
GetPhysicalDeviceFeatures2KHR:                                   ProcGetPhysicalDeviceFeatures2KHR
GetPhysicalDeviceFormatProperties:                               ProcGetPhysicalDeviceFormatProperties
GetPhysicalDeviceFormatProperties2:                              ProcGetPhysicalDeviceFormatProperties2
GetPhysicalDeviceFormatProperties2KHR:                           ProcGetPhysicalDeviceFormatProperties2KHR
GetPhysicalDeviceFragmentShadingRatesKHR:                        ProcGetPhysicalDeviceFragmentShadingRatesKHR
GetPhysicalDeviceImageFormatProperties:                          ProcGetPhysicalDeviceImageFormatProperties
GetPhysicalDeviceImageFormatProperties2:                         ProcGetPhysicalDeviceImageFormatProperties2
GetPhysicalDeviceImageFormatProperties2KHR:                      ProcGetPhysicalDeviceImageFormatProperties2KHR
GetPhysicalDeviceMemoryProperties:                               ProcGetPhysicalDeviceMemoryProperties
GetPhysicalDeviceMemoryProperties2:                              ProcGetPhysicalDeviceMemoryProperties2
GetPhysicalDeviceMemoryProperties2KHR:                           ProcGetPhysicalDeviceMemoryProperties2KHR
GetPhysicalDeviceMultisamplePropertiesEXT:                       ProcGetPhysicalDeviceMultisamplePropertiesEXT
GetPhysicalDeviceOpticalFlowImageFormatsNV:                      ProcGetPhysicalDeviceOpticalFlowImageFormatsNV
GetPhysicalDevicePresentRectanglesKHR:                           ProcGetPhysicalDevicePresentRectanglesKHR
GetPhysicalDeviceProperties:                                     ProcGetPhysicalDeviceProperties
GetPhysicalDeviceProperties2:                                    ProcGetPhysicalDeviceProperties2
GetPhysicalDeviceProperties2KHR:                                 ProcGetPhysicalDeviceProperties2KHR
GetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR:           ProcGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR
GetPhysicalDeviceQueueFamilyProperties:                          ProcGetPhysicalDeviceQueueFamilyProperties
GetPhysicalDeviceQueueFamilyProperties2:                         ProcGetPhysicalDeviceQueueFamilyProperties2
GetPhysicalDeviceQueueFamilyProperties2KHR:                      ProcGetPhysicalDeviceQueueFamilyProperties2KHR
GetPhysicalDeviceSparseImageFormatProperties:                    ProcGetPhysicalDeviceSparseImageFormatProperties
GetPhysicalDeviceSparseImageFormatProperties2:                   ProcGetPhysicalDeviceSparseImageFormatProperties2
GetPhysicalDeviceSparseImageFormatProperties2KHR:                ProcGetPhysicalDeviceSparseImageFormatProperties2KHR
GetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV: ProcGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV
GetPhysicalDeviceSurfaceCapabilities2EXT:                        ProcGetPhysicalDeviceSurfaceCapabilities2EXT
GetPhysicalDeviceSurfaceCapabilities2KHR:                        ProcGetPhysicalDeviceSurfaceCapabilities2KHR
GetPhysicalDeviceSurfaceCapabilitiesKHR:                         ProcGetPhysicalDeviceSurfaceCapabilitiesKHR
GetPhysicalDeviceSurfaceFormats2KHR:                             ProcGetPhysicalDeviceSurfaceFormats2KHR
GetPhysicalDeviceSurfaceFormatsKHR:                              ProcGetPhysicalDeviceSurfaceFormatsKHR
GetPhysicalDeviceSurfacePresentModes2EXT:                        ProcGetPhysicalDeviceSurfacePresentModes2EXT
GetPhysicalDeviceSurfacePresentModesKHR:                         ProcGetPhysicalDeviceSurfacePresentModesKHR
GetPhysicalDeviceSurfaceSupportKHR:                              ProcGetPhysicalDeviceSurfaceSupportKHR
GetPhysicalDeviceToolProperties:                                 ProcGetPhysicalDeviceToolProperties
GetPhysicalDeviceToolPropertiesEXT:                              ProcGetPhysicalDeviceToolPropertiesEXT
GetPhysicalDeviceVideoCapabilitiesKHR:                           ProcGetPhysicalDeviceVideoCapabilitiesKHR
GetPhysicalDeviceVideoFormatPropertiesKHR:                       ProcGetPhysicalDeviceVideoFormatPropertiesKHR
GetPhysicalDeviceWaylandPresentationSupportKHR:                  ProcGetPhysicalDeviceWaylandPresentationSupportKHR
GetPhysicalDeviceWin32PresentationSupportKHR:                    ProcGetPhysicalDeviceWin32PresentationSupportKHR
GetWinrtDisplayNV:                                               ProcGetWinrtDisplayNV
ReleaseDisplayEXT:                                               ProcReleaseDisplayEXT
SubmitDebugUtilsMessageEXT:                                      ProcSubmitDebugUtilsMessageEXT

// Device Procedures
AcquireFullScreenExclusiveModeEXT:                      ProcAcquireFullScreenExclusiveModeEXT
AcquireNextImage2KHR:                                   ProcAcquireNextImage2KHR
AcquireNextImageKHR:                                    ProcAcquireNextImageKHR
AcquirePerformanceConfigurationINTEL:                   ProcAcquirePerformanceConfigurationINTEL
AcquireProfilingLockKHR:                                ProcAcquireProfilingLockKHR
AllocateCommandBuffers:                                 ProcAllocateCommandBuffers
AllocateDescriptorSets:                                 ProcAllocateDescriptorSets
AllocateMemory:                                         ProcAllocateMemory
BeginCommandBuffer:                                     ProcBeginCommandBuffer
BindAccelerationStructureMemoryNV:                      ProcBindAccelerationStructureMemoryNV
BindBufferMemory:                                       ProcBindBufferMemory
BindBufferMemory2:                                      ProcBindBufferMemory2
BindBufferMemory2KHR:                                   ProcBindBufferMemory2KHR
BindImageMemory:                                        ProcBindImageMemory
BindImageMemory2:                                       ProcBindImageMemory2
BindImageMemory2KHR:                                    ProcBindImageMemory2KHR
BindOpticalFlowSessionImageNV:                          ProcBindOpticalFlowSessionImageNV
BindVideoSessionMemoryKHR:                              ProcBindVideoSessionMemoryKHR
BuildAccelerationStructuresKHR:                         ProcBuildAccelerationStructuresKHR
BuildMicromapsEXT:                                      ProcBuildMicromapsEXT
CmdBeginConditionalRenderingEXT:                        ProcCmdBeginConditionalRenderingEXT
CmdBeginDebugUtilsLabelEXT:                             ProcCmdBeginDebugUtilsLabelEXT
CmdBeginQuery:                                          ProcCmdBeginQuery
CmdBeginQueryIndexedEXT:                                ProcCmdBeginQueryIndexedEXT
CmdBeginRenderPass:                                     ProcCmdBeginRenderPass
CmdBeginRenderPass2:                                    ProcCmdBeginRenderPass2
CmdBeginRenderPass2KHR:                                 ProcCmdBeginRenderPass2KHR
CmdBeginRendering:                                      ProcCmdBeginRendering
CmdBeginRenderingKHR:                                   ProcCmdBeginRenderingKHR
CmdBeginTransformFeedbackEXT:                           ProcCmdBeginTransformFeedbackEXT
CmdBeginVideoCodingKHR:                                 ProcCmdBeginVideoCodingKHR
CmdBindDescriptorBufferEmbeddedSamplersEXT:             ProcCmdBindDescriptorBufferEmbeddedSamplersEXT
CmdBindDescriptorBuffersEXT:                            ProcCmdBindDescriptorBuffersEXT
CmdBindDescriptorSets:                                  ProcCmdBindDescriptorSets
CmdBindIndexBuffer:                                     ProcCmdBindIndexBuffer
CmdBindInvocationMaskHUAWEI:                            ProcCmdBindInvocationMaskHUAWEI
CmdBindPipeline:                                        ProcCmdBindPipeline
CmdBindPipelineShaderGroupNV:                           ProcCmdBindPipelineShaderGroupNV
CmdBindShadersEXT:                                      ProcCmdBindShadersEXT
CmdBindShadingRateImageNV:                              ProcCmdBindShadingRateImageNV
CmdBindTransformFeedbackBuffersEXT:                     ProcCmdBindTransformFeedbackBuffersEXT
CmdBindVertexBuffers:                                   ProcCmdBindVertexBuffers
CmdBindVertexBuffers2:                                  ProcCmdBindVertexBuffers2
CmdBindVertexBuffers2EXT:                               ProcCmdBindVertexBuffers2EXT
CmdBlitImage:                                           ProcCmdBlitImage
CmdBlitImage2:                                          ProcCmdBlitImage2
CmdBlitImage2KHR:                                       ProcCmdBlitImage2KHR
CmdBuildAccelerationStructureNV:                        ProcCmdBuildAccelerationStructureNV
CmdBuildAccelerationStructuresIndirectKHR:              ProcCmdBuildAccelerationStructuresIndirectKHR
CmdBuildAccelerationStructuresKHR:                      ProcCmdBuildAccelerationStructuresKHR
CmdBuildMicromapsEXT:                                   ProcCmdBuildMicromapsEXT
CmdClearAttachments:                                    ProcCmdClearAttachments
CmdClearColorImage:                                     ProcCmdClearColorImage
CmdClearDepthStencilImage:                              ProcCmdClearDepthStencilImage
CmdControlVideoCodingKHR:                               ProcCmdControlVideoCodingKHR
CmdCopyAccelerationStructureKHR:                        ProcCmdCopyAccelerationStructureKHR
CmdCopyAccelerationStructureNV:                         ProcCmdCopyAccelerationStructureNV
CmdCopyAccelerationStructureToMemoryKHR:                ProcCmdCopyAccelerationStructureToMemoryKHR
CmdCopyBuffer:                                          ProcCmdCopyBuffer
CmdCopyBuffer2:                                         ProcCmdCopyBuffer2
CmdCopyBuffer2KHR:                                      ProcCmdCopyBuffer2KHR
CmdCopyBufferToImage:                                   ProcCmdCopyBufferToImage
CmdCopyBufferToImage2:                                  ProcCmdCopyBufferToImage2
CmdCopyBufferToImage2KHR:                               ProcCmdCopyBufferToImage2KHR
CmdCopyImage:                                           ProcCmdCopyImage
CmdCopyImage2:                                          ProcCmdCopyImage2
CmdCopyImage2KHR:                                       ProcCmdCopyImage2KHR
CmdCopyImageToBuffer:                                   ProcCmdCopyImageToBuffer
CmdCopyImageToBuffer2:                                  ProcCmdCopyImageToBuffer2
CmdCopyImageToBuffer2KHR:                               ProcCmdCopyImageToBuffer2KHR
CmdCopyMemoryIndirectNV:                                ProcCmdCopyMemoryIndirectNV
CmdCopyMemoryToAccelerationStructureKHR:                ProcCmdCopyMemoryToAccelerationStructureKHR
CmdCopyMemoryToImageIndirectNV:                         ProcCmdCopyMemoryToImageIndirectNV
CmdCopyMemoryToMicromapEXT:                             ProcCmdCopyMemoryToMicromapEXT
CmdCopyMicromapEXT:                                     ProcCmdCopyMicromapEXT
CmdCopyMicromapToMemoryEXT:                             ProcCmdCopyMicromapToMemoryEXT
CmdCopyQueryPoolResults:                                ProcCmdCopyQueryPoolResults
CmdCuLaunchKernelNVX:                                   ProcCmdCuLaunchKernelNVX
CmdDebugMarkerBeginEXT:                                 ProcCmdDebugMarkerBeginEXT
CmdDebugMarkerEndEXT:                                   ProcCmdDebugMarkerEndEXT
CmdDebugMarkerInsertEXT:                                ProcCmdDebugMarkerInsertEXT
CmdDecodeVideoKHR:                                      ProcCmdDecodeVideoKHR
CmdDecompressMemoryIndirectCountNV:                     ProcCmdDecompressMemoryIndirectCountNV
CmdDecompressMemoryNV:                                  ProcCmdDecompressMemoryNV
CmdDispatch:                                            ProcCmdDispatch
CmdDispatchBase:                                        ProcCmdDispatchBase
CmdDispatchBaseKHR:                                     ProcCmdDispatchBaseKHR
CmdDispatchIndirect:                                    ProcCmdDispatchIndirect
CmdDraw:                                                ProcCmdDraw
CmdDrawClusterHUAWEI:                                   ProcCmdDrawClusterHUAWEI
CmdDrawClusterIndirectHUAWEI:                           ProcCmdDrawClusterIndirectHUAWEI
CmdDrawIndexed:                                         ProcCmdDrawIndexed
CmdDrawIndexedIndirect:                                 ProcCmdDrawIndexedIndirect
CmdDrawIndexedIndirectCount:                            ProcCmdDrawIndexedIndirectCount
CmdDrawIndexedIndirectCountAMD:                         ProcCmdDrawIndexedIndirectCountAMD
CmdDrawIndexedIndirectCountKHR:                         ProcCmdDrawIndexedIndirectCountKHR
CmdDrawIndirect:                                        ProcCmdDrawIndirect
CmdDrawIndirectByteCountEXT:                            ProcCmdDrawIndirectByteCountEXT
CmdDrawIndirectCount:                                   ProcCmdDrawIndirectCount
CmdDrawIndirectCountAMD:                                ProcCmdDrawIndirectCountAMD
CmdDrawIndirectCountKHR:                                ProcCmdDrawIndirectCountKHR
CmdDrawMeshTasksEXT:                                    ProcCmdDrawMeshTasksEXT
CmdDrawMeshTasksIndirectCountEXT:                       ProcCmdDrawMeshTasksIndirectCountEXT
CmdDrawMeshTasksIndirectCountNV:                        ProcCmdDrawMeshTasksIndirectCountNV
CmdDrawMeshTasksIndirectEXT:                            ProcCmdDrawMeshTasksIndirectEXT
CmdDrawMeshTasksIndirectNV:                             ProcCmdDrawMeshTasksIndirectNV
CmdDrawMeshTasksNV:                                     ProcCmdDrawMeshTasksNV
CmdDrawMultiEXT:                                        ProcCmdDrawMultiEXT
CmdDrawMultiIndexedEXT:                                 ProcCmdDrawMultiIndexedEXT
CmdEndConditionalRenderingEXT:                          ProcCmdEndConditionalRenderingEXT
CmdEndDebugUtilsLabelEXT:                               ProcCmdEndDebugUtilsLabelEXT
CmdEndQuery:                                            ProcCmdEndQuery
CmdEndQueryIndexedEXT:                                  ProcCmdEndQueryIndexedEXT
CmdEndRenderPass:                                       ProcCmdEndRenderPass
CmdEndRenderPass2:                                      ProcCmdEndRenderPass2
CmdEndRenderPass2KHR:                                   ProcCmdEndRenderPass2KHR
CmdEndRendering:                                        ProcCmdEndRendering
CmdEndRenderingKHR:                                     ProcCmdEndRenderingKHR
CmdEndTransformFeedbackEXT:                             ProcCmdEndTransformFeedbackEXT
CmdEndVideoCodingKHR:                                   ProcCmdEndVideoCodingKHR
CmdExecuteCommands:                                     ProcCmdExecuteCommands
CmdExecuteGeneratedCommandsNV:                          ProcCmdExecuteGeneratedCommandsNV
CmdFillBuffer:                                          ProcCmdFillBuffer
CmdInsertDebugUtilsLabelEXT:                            ProcCmdInsertDebugUtilsLabelEXT
CmdNextSubpass:                                         ProcCmdNextSubpass
CmdNextSubpass2:                                        ProcCmdNextSubpass2
CmdNextSubpass2KHR:                                     ProcCmdNextSubpass2KHR
CmdOpticalFlowExecuteNV:                                ProcCmdOpticalFlowExecuteNV
CmdPipelineBarrier:                                     ProcCmdPipelineBarrier
CmdPipelineBarrier2:                                    ProcCmdPipelineBarrier2
CmdPipelineBarrier2KHR:                                 ProcCmdPipelineBarrier2KHR
CmdPreprocessGeneratedCommandsNV:                       ProcCmdPreprocessGeneratedCommandsNV
CmdPushConstants:                                       ProcCmdPushConstants
CmdPushDescriptorSetKHR:                                ProcCmdPushDescriptorSetKHR
CmdPushDescriptorSetWithTemplateKHR:                    ProcCmdPushDescriptorSetWithTemplateKHR
CmdResetEvent:                                          ProcCmdResetEvent
CmdResetEvent2:                                         ProcCmdResetEvent2
CmdResetEvent2KHR:                                      ProcCmdResetEvent2KHR
CmdResetQueryPool:                                      ProcCmdResetQueryPool
CmdResolveImage:                                        ProcCmdResolveImage
CmdResolveImage2:                                       ProcCmdResolveImage2
CmdResolveImage2KHR:                                    ProcCmdResolveImage2KHR
CmdSetAlphaToCoverageEnableEXT:                         ProcCmdSetAlphaToCoverageEnableEXT
CmdSetAlphaToOneEnableEXT:                              ProcCmdSetAlphaToOneEnableEXT
CmdSetAttachmentFeedbackLoopEnableEXT:                  ProcCmdSetAttachmentFeedbackLoopEnableEXT
CmdSetBlendConstants:                                   ProcCmdSetBlendConstants
CmdSetCheckpointNV:                                     ProcCmdSetCheckpointNV
CmdSetCoarseSampleOrderNV:                              ProcCmdSetCoarseSampleOrderNV
CmdSetColorBlendAdvancedEXT:                            ProcCmdSetColorBlendAdvancedEXT
CmdSetColorBlendEnableEXT:                              ProcCmdSetColorBlendEnableEXT
CmdSetColorBlendEquationEXT:                            ProcCmdSetColorBlendEquationEXT
CmdSetColorWriteMaskEXT:                                ProcCmdSetColorWriteMaskEXT
CmdSetConservativeRasterizationModeEXT:                 ProcCmdSetConservativeRasterizationModeEXT
CmdSetCoverageModulationModeNV:                         ProcCmdSetCoverageModulationModeNV
CmdSetCoverageModulationTableEnableNV:                  ProcCmdSetCoverageModulationTableEnableNV
CmdSetCoverageModulationTableNV:                        ProcCmdSetCoverageModulationTableNV
CmdSetCoverageReductionModeNV:                          ProcCmdSetCoverageReductionModeNV
CmdSetCoverageToColorEnableNV:                          ProcCmdSetCoverageToColorEnableNV
CmdSetCoverageToColorLocationNV:                        ProcCmdSetCoverageToColorLocationNV
CmdSetCullMode:                                         ProcCmdSetCullMode
CmdSetCullModeEXT:                                      ProcCmdSetCullModeEXT
CmdSetDepthBias:                                        ProcCmdSetDepthBias
CmdSetDepthBiasEnable:                                  ProcCmdSetDepthBiasEnable
CmdSetDepthBiasEnableEXT:                               ProcCmdSetDepthBiasEnableEXT
CmdSetDepthBounds:                                      ProcCmdSetDepthBounds
CmdSetDepthBoundsTestEnable:                            ProcCmdSetDepthBoundsTestEnable
CmdSetDepthBoundsTestEnableEXT:                         ProcCmdSetDepthBoundsTestEnableEXT
CmdSetDepthClampEnableEXT:                              ProcCmdSetDepthClampEnableEXT
CmdSetDepthClipEnableEXT:                               ProcCmdSetDepthClipEnableEXT
CmdSetDepthClipNegativeOneToOneEXT:                     ProcCmdSetDepthClipNegativeOneToOneEXT
CmdSetDepthCompareOp:                                   ProcCmdSetDepthCompareOp
CmdSetDepthCompareOpEXT:                                ProcCmdSetDepthCompareOpEXT
CmdSetDepthTestEnable:                                  ProcCmdSetDepthTestEnable
CmdSetDepthTestEnableEXT:                               ProcCmdSetDepthTestEnableEXT
CmdSetDepthWriteEnable:                                 ProcCmdSetDepthWriteEnable
CmdSetDepthWriteEnableEXT:                              ProcCmdSetDepthWriteEnableEXT
CmdSetDescriptorBufferOffsetsEXT:                       ProcCmdSetDescriptorBufferOffsetsEXT
CmdSetDeviceMask:                                       ProcCmdSetDeviceMask
CmdSetDeviceMaskKHR:                                    ProcCmdSetDeviceMaskKHR
CmdSetDiscardRectangleEXT:                              ProcCmdSetDiscardRectangleEXT
CmdSetDiscardRectangleEnableEXT:                        ProcCmdSetDiscardRectangleEnableEXT
CmdSetDiscardRectangleModeEXT:                          ProcCmdSetDiscardRectangleModeEXT
CmdSetEvent:                                            ProcCmdSetEvent
CmdSetEvent2:                                           ProcCmdSetEvent2
CmdSetEvent2KHR:                                        ProcCmdSetEvent2KHR
CmdSetExclusiveScissorEnableNV:                         ProcCmdSetExclusiveScissorEnableNV
CmdSetExclusiveScissorNV:                               ProcCmdSetExclusiveScissorNV
CmdSetExtraPrimitiveOverestimationSizeEXT:              ProcCmdSetExtraPrimitiveOverestimationSizeEXT
CmdSetFragmentShadingRateEnumNV:                        ProcCmdSetFragmentShadingRateEnumNV
CmdSetFragmentShadingRateKHR:                           ProcCmdSetFragmentShadingRateKHR
CmdSetFrontFace:                                        ProcCmdSetFrontFace
CmdSetFrontFaceEXT:                                     ProcCmdSetFrontFaceEXT
CmdSetLineRasterizationModeEXT:                         ProcCmdSetLineRasterizationModeEXT
CmdSetLineStippleEXT:                                   ProcCmdSetLineStippleEXT
CmdSetLineStippleEnableEXT:                             ProcCmdSetLineStippleEnableEXT
CmdSetLineWidth:                                        ProcCmdSetLineWidth
CmdSetLogicOpEXT:                                       ProcCmdSetLogicOpEXT
CmdSetLogicOpEnableEXT:                                 ProcCmdSetLogicOpEnableEXT
CmdSetPatchControlPointsEXT:                            ProcCmdSetPatchControlPointsEXT
CmdSetPerformanceMarkerINTEL:                           ProcCmdSetPerformanceMarkerINTEL
CmdSetPerformanceOverrideINTEL:                         ProcCmdSetPerformanceOverrideINTEL
CmdSetPerformanceStreamMarkerINTEL:                     ProcCmdSetPerformanceStreamMarkerINTEL
CmdSetPolygonModeEXT:                                   ProcCmdSetPolygonModeEXT
CmdSetPrimitiveRestartEnable:                           ProcCmdSetPrimitiveRestartEnable
CmdSetPrimitiveRestartEnableEXT:                        ProcCmdSetPrimitiveRestartEnableEXT
CmdSetPrimitiveTopology:                                ProcCmdSetPrimitiveTopology
CmdSetPrimitiveTopologyEXT:                             ProcCmdSetPrimitiveTopologyEXT
CmdSetProvokingVertexModeEXT:                           ProcCmdSetProvokingVertexModeEXT
CmdSetRasterizationSamplesEXT:                          ProcCmdSetRasterizationSamplesEXT
CmdSetRasterizationStreamEXT:                           ProcCmdSetRasterizationStreamEXT
CmdSetRasterizerDiscardEnable:                          ProcCmdSetRasterizerDiscardEnable
CmdSetRasterizerDiscardEnableEXT:                       ProcCmdSetRasterizerDiscardEnableEXT
CmdSetRayTracingPipelineStackSizeKHR:                   ProcCmdSetRayTracingPipelineStackSizeKHR
CmdSetRepresentativeFragmentTestEnableNV:               ProcCmdSetRepresentativeFragmentTestEnableNV
CmdSetSampleLocationsEXT:                               ProcCmdSetSampleLocationsEXT
CmdSetSampleLocationsEnableEXT:                         ProcCmdSetSampleLocationsEnableEXT
CmdSetSampleMaskEXT:                                    ProcCmdSetSampleMaskEXT
CmdSetScissor:                                          ProcCmdSetScissor
CmdSetScissorWithCount:                                 ProcCmdSetScissorWithCount
CmdSetScissorWithCountEXT:                              ProcCmdSetScissorWithCountEXT
CmdSetShadingRateImageEnableNV:                         ProcCmdSetShadingRateImageEnableNV
CmdSetStencilCompareMask:                               ProcCmdSetStencilCompareMask
CmdSetStencilOp:                                        ProcCmdSetStencilOp
CmdSetStencilOpEXT:                                     ProcCmdSetStencilOpEXT
CmdSetStencilReference:                                 ProcCmdSetStencilReference
CmdSetStencilTestEnable:                                ProcCmdSetStencilTestEnable
CmdSetStencilTestEnableEXT:                             ProcCmdSetStencilTestEnableEXT
CmdSetStencilWriteMask:                                 ProcCmdSetStencilWriteMask
CmdSetTessellationDomainOriginEXT:                      ProcCmdSetTessellationDomainOriginEXT
CmdSetVertexInputEXT:                                   ProcCmdSetVertexInputEXT
CmdSetViewport:                                         ProcCmdSetViewport
CmdSetViewportShadingRatePaletteNV:                     ProcCmdSetViewportShadingRatePaletteNV
CmdSetViewportSwizzleNV:                                ProcCmdSetViewportSwizzleNV
CmdSetViewportWScalingEnableNV:                         ProcCmdSetViewportWScalingEnableNV
CmdSetViewportWScalingNV:                               ProcCmdSetViewportWScalingNV
CmdSetViewportWithCount:                                ProcCmdSetViewportWithCount
CmdSetViewportWithCountEXT:                             ProcCmdSetViewportWithCountEXT
CmdSubpassShadingHUAWEI:                                ProcCmdSubpassShadingHUAWEI
CmdTraceRaysIndirect2KHR:                               ProcCmdTraceRaysIndirect2KHR
CmdTraceRaysIndirectKHR:                                ProcCmdTraceRaysIndirectKHR
CmdTraceRaysKHR:                                        ProcCmdTraceRaysKHR
CmdTraceRaysNV:                                         ProcCmdTraceRaysNV
CmdUpdateBuffer:                                        ProcCmdUpdateBuffer
CmdWaitEvents:                                          ProcCmdWaitEvents
CmdWaitEvents2:                                         ProcCmdWaitEvents2
CmdWaitEvents2KHR:                                      ProcCmdWaitEvents2KHR
CmdWriteAccelerationStructuresPropertiesKHR:            ProcCmdWriteAccelerationStructuresPropertiesKHR
CmdWriteAccelerationStructuresPropertiesNV:             ProcCmdWriteAccelerationStructuresPropertiesNV
CmdWriteBufferMarker2AMD:                               ProcCmdWriteBufferMarker2AMD
CmdWriteBufferMarkerAMD:                                ProcCmdWriteBufferMarkerAMD
CmdWriteMicromapsPropertiesEXT:                         ProcCmdWriteMicromapsPropertiesEXT
CmdWriteTimestamp:                                      ProcCmdWriteTimestamp
CmdWriteTimestamp2:                                     ProcCmdWriteTimestamp2
CmdWriteTimestamp2KHR:                                  ProcCmdWriteTimestamp2KHR
CompileDeferredNV:                                      ProcCompileDeferredNV
CopyAccelerationStructureKHR:                           ProcCopyAccelerationStructureKHR
CopyAccelerationStructureToMemoryKHR:                   ProcCopyAccelerationStructureToMemoryKHR
CopyMemoryToAccelerationStructureKHR:                   ProcCopyMemoryToAccelerationStructureKHR
CopyMemoryToMicromapEXT:                                ProcCopyMemoryToMicromapEXT
CopyMicromapEXT:                                        ProcCopyMicromapEXT
CopyMicromapToMemoryEXT:                                ProcCopyMicromapToMemoryEXT
CreateAccelerationStructureKHR:                         ProcCreateAccelerationStructureKHR
CreateAccelerationStructureNV:                          ProcCreateAccelerationStructureNV
CreateBuffer:                                           ProcCreateBuffer
CreateBufferView:                                       ProcCreateBufferView
CreateCommandPool:                                      ProcCreateCommandPool
CreateComputePipelines:                                 ProcCreateComputePipelines
CreateCuFunctionNVX:                                    ProcCreateCuFunctionNVX
CreateCuModuleNVX:                                      ProcCreateCuModuleNVX
CreateDeferredOperationKHR:                             ProcCreateDeferredOperationKHR
CreateDescriptorPool:                                   ProcCreateDescriptorPool
CreateDescriptorSetLayout:                              ProcCreateDescriptorSetLayout
CreateDescriptorUpdateTemplate:                         ProcCreateDescriptorUpdateTemplate
CreateDescriptorUpdateTemplateKHR:                      ProcCreateDescriptorUpdateTemplateKHR
CreateEvent:                                            ProcCreateEvent
CreateFence:                                            ProcCreateFence
CreateFramebuffer:                                      ProcCreateFramebuffer
CreateGraphicsPipelines:                                ProcCreateGraphicsPipelines
CreateImage:                                            ProcCreateImage
CreateImageView:                                        ProcCreateImageView
CreateIndirectCommandsLayoutNV:                         ProcCreateIndirectCommandsLayoutNV
CreateMicromapEXT:                                      ProcCreateMicromapEXT
CreateOpticalFlowSessionNV:                             ProcCreateOpticalFlowSessionNV
CreatePipelineCache:                                    ProcCreatePipelineCache
CreatePipelineLayout:                                   ProcCreatePipelineLayout
CreatePrivateDataSlot:                                  ProcCreatePrivateDataSlot
CreatePrivateDataSlotEXT:                               ProcCreatePrivateDataSlotEXT
CreateQueryPool:                                        ProcCreateQueryPool
CreateRayTracingPipelinesKHR:                           ProcCreateRayTracingPipelinesKHR
CreateRayTracingPipelinesNV:                            ProcCreateRayTracingPipelinesNV
CreateRenderPass:                                       ProcCreateRenderPass
CreateRenderPass2:                                      ProcCreateRenderPass2
CreateRenderPass2KHR:                                   ProcCreateRenderPass2KHR
CreateSampler:                                          ProcCreateSampler
CreateSamplerYcbcrConversion:                           ProcCreateSamplerYcbcrConversion
CreateSamplerYcbcrConversionKHR:                        ProcCreateSamplerYcbcrConversionKHR
CreateSemaphore:                                        ProcCreateSemaphore
CreateShaderModule:                                     ProcCreateShaderModule
CreateShadersEXT:                                       ProcCreateShadersEXT
CreateSharedSwapchainsKHR:                              ProcCreateSharedSwapchainsKHR
CreateSwapchainKHR:                                     ProcCreateSwapchainKHR
CreateValidationCacheEXT:                               ProcCreateValidationCacheEXT
CreateVideoSessionKHR:                                  ProcCreateVideoSessionKHR
CreateVideoSessionParametersKHR:                        ProcCreateVideoSessionParametersKHR
DebugMarkerSetObjectNameEXT:                            ProcDebugMarkerSetObjectNameEXT
DebugMarkerSetObjectTagEXT:                             ProcDebugMarkerSetObjectTagEXT
DeferredOperationJoinKHR:                               ProcDeferredOperationJoinKHR
DestroyAccelerationStructureKHR:                        ProcDestroyAccelerationStructureKHR
DestroyAccelerationStructureNV:                         ProcDestroyAccelerationStructureNV
DestroyBuffer:                                          ProcDestroyBuffer
DestroyBufferView:                                      ProcDestroyBufferView
DestroyCommandPool:                                     ProcDestroyCommandPool
DestroyCuFunctionNVX:                                   ProcDestroyCuFunctionNVX
DestroyCuModuleNVX:                                     ProcDestroyCuModuleNVX
DestroyDeferredOperationKHR:                            ProcDestroyDeferredOperationKHR
DestroyDescriptorPool:                                  ProcDestroyDescriptorPool
DestroyDescriptorSetLayout:                             ProcDestroyDescriptorSetLayout
DestroyDescriptorUpdateTemplate:                        ProcDestroyDescriptorUpdateTemplate
DestroyDescriptorUpdateTemplateKHR:                     ProcDestroyDescriptorUpdateTemplateKHR
DestroyDevice:                                          ProcDestroyDevice
DestroyEvent:                                           ProcDestroyEvent
DestroyFence:                                           ProcDestroyFence
DestroyFramebuffer:                                     ProcDestroyFramebuffer
DestroyImage:                                           ProcDestroyImage
DestroyImageView:                                       ProcDestroyImageView
DestroyIndirectCommandsLayoutNV:                        ProcDestroyIndirectCommandsLayoutNV
DestroyMicromapEXT:                                     ProcDestroyMicromapEXT
DestroyOpticalFlowSessionNV:                            ProcDestroyOpticalFlowSessionNV
DestroyPipeline:                                        ProcDestroyPipeline
DestroyPipelineCache:                                   ProcDestroyPipelineCache
DestroyPipelineLayout:                                  ProcDestroyPipelineLayout
DestroyPrivateDataSlot:                                 ProcDestroyPrivateDataSlot
DestroyPrivateDataSlotEXT:                              ProcDestroyPrivateDataSlotEXT
DestroyQueryPool:                                       ProcDestroyQueryPool
DestroyRenderPass:                                      ProcDestroyRenderPass
DestroySampler:                                         ProcDestroySampler
DestroySamplerYcbcrConversion:                          ProcDestroySamplerYcbcrConversion
DestroySamplerYcbcrConversionKHR:                       ProcDestroySamplerYcbcrConversionKHR
DestroySemaphore:                                       ProcDestroySemaphore
DestroyShaderEXT:                                       ProcDestroyShaderEXT
DestroyShaderModule:                                    ProcDestroyShaderModule
DestroySwapchainKHR:                                    ProcDestroySwapchainKHR
DestroyValidationCacheEXT:                              ProcDestroyValidationCacheEXT
DestroyVideoSessionKHR:                                 ProcDestroyVideoSessionKHR
DestroyVideoSessionParametersKHR:                       ProcDestroyVideoSessionParametersKHR
DeviceWaitIdle:                                         ProcDeviceWaitIdle
DisplayPowerControlEXT:                                 ProcDisplayPowerControlEXT
EndCommandBuffer:                                       ProcEndCommandBuffer
ExportMetalObjectsEXT:                                  ProcExportMetalObjectsEXT
FlushMappedMemoryRanges:                                ProcFlushMappedMemoryRanges
FreeCommandBuffers:                                     ProcFreeCommandBuffers
FreeDescriptorSets:                                     ProcFreeDescriptorSets
FreeMemory:                                             ProcFreeMemory
GetAccelerationStructureBuildSizesKHR:                  ProcGetAccelerationStructureBuildSizesKHR
GetAccelerationStructureDeviceAddressKHR:               ProcGetAccelerationStructureDeviceAddressKHR
GetAccelerationStructureHandleNV:                       ProcGetAccelerationStructureHandleNV
GetAccelerationStructureMemoryRequirementsNV:           ProcGetAccelerationStructureMemoryRequirementsNV
GetAccelerationStructureOpaqueCaptureDescriptorDataEXT: ProcGetAccelerationStructureOpaqueCaptureDescriptorDataEXT
GetBufferDeviceAddress:                                 ProcGetBufferDeviceAddress
GetBufferDeviceAddressEXT:                              ProcGetBufferDeviceAddressEXT
GetBufferDeviceAddressKHR:                              ProcGetBufferDeviceAddressKHR
GetBufferMemoryRequirements:                            ProcGetBufferMemoryRequirements
GetBufferMemoryRequirements2:                           ProcGetBufferMemoryRequirements2
GetBufferMemoryRequirements2KHR:                        ProcGetBufferMemoryRequirements2KHR
GetBufferOpaqueCaptureAddress:                          ProcGetBufferOpaqueCaptureAddress
GetBufferOpaqueCaptureAddressKHR:                       ProcGetBufferOpaqueCaptureAddressKHR
GetBufferOpaqueCaptureDescriptorDataEXT:                ProcGetBufferOpaqueCaptureDescriptorDataEXT
GetCalibratedTimestampsEXT:                             ProcGetCalibratedTimestampsEXT
GetDeferredOperationMaxConcurrencyKHR:                  ProcGetDeferredOperationMaxConcurrencyKHR
GetDeferredOperationResultKHR:                          ProcGetDeferredOperationResultKHR
GetDescriptorEXT:                                       ProcGetDescriptorEXT
GetDescriptorSetHostMappingVALVE:                       ProcGetDescriptorSetHostMappingVALVE
GetDescriptorSetLayoutBindingOffsetEXT:                 ProcGetDescriptorSetLayoutBindingOffsetEXT
GetDescriptorSetLayoutHostMappingInfoVALVE:             ProcGetDescriptorSetLayoutHostMappingInfoVALVE
GetDescriptorSetLayoutSizeEXT:                          ProcGetDescriptorSetLayoutSizeEXT
GetDescriptorSetLayoutSupport:                          ProcGetDescriptorSetLayoutSupport
GetDescriptorSetLayoutSupportKHR:                       ProcGetDescriptorSetLayoutSupportKHR
GetDeviceAccelerationStructureCompatibilityKHR:         ProcGetDeviceAccelerationStructureCompatibilityKHR
GetDeviceBufferMemoryRequirements:                      ProcGetDeviceBufferMemoryRequirements
GetDeviceBufferMemoryRequirementsKHR:                   ProcGetDeviceBufferMemoryRequirementsKHR
GetDeviceFaultInfoEXT:                                  ProcGetDeviceFaultInfoEXT
GetDeviceGroupPeerMemoryFeatures:                       ProcGetDeviceGroupPeerMemoryFeatures
GetDeviceGroupPeerMemoryFeaturesKHR:                    ProcGetDeviceGroupPeerMemoryFeaturesKHR
GetDeviceGroupPresentCapabilitiesKHR:                   ProcGetDeviceGroupPresentCapabilitiesKHR
GetDeviceGroupSurfacePresentModes2EXT:                  ProcGetDeviceGroupSurfacePresentModes2EXT
GetDeviceGroupSurfacePresentModesKHR:                   ProcGetDeviceGroupSurfacePresentModesKHR
GetDeviceImageMemoryRequirements:                       ProcGetDeviceImageMemoryRequirements
GetDeviceImageMemoryRequirementsKHR:                    ProcGetDeviceImageMemoryRequirementsKHR
GetDeviceImageSparseMemoryRequirements:                 ProcGetDeviceImageSparseMemoryRequirements
GetDeviceImageSparseMemoryRequirementsKHR:              ProcGetDeviceImageSparseMemoryRequirementsKHR
GetDeviceMemoryCommitment:                              ProcGetDeviceMemoryCommitment
GetDeviceMemoryOpaqueCaptureAddress:                    ProcGetDeviceMemoryOpaqueCaptureAddress
GetDeviceMemoryOpaqueCaptureAddressKHR:                 ProcGetDeviceMemoryOpaqueCaptureAddressKHR
GetDeviceMicromapCompatibilityEXT:                      ProcGetDeviceMicromapCompatibilityEXT
GetDeviceProcAddr:                                      ProcGetDeviceProcAddr
GetDeviceQueue:                                         ProcGetDeviceQueue
GetDeviceQueue2:                                        ProcGetDeviceQueue2
GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI:          ProcGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI
GetDynamicRenderingTilePropertiesQCOM:                  ProcGetDynamicRenderingTilePropertiesQCOM
GetEventStatus:                                         ProcGetEventStatus
GetFenceFdKHR:                                          ProcGetFenceFdKHR
GetFenceStatus:                                         ProcGetFenceStatus
GetFenceWin32HandleKHR:                                 ProcGetFenceWin32HandleKHR
GetFramebufferTilePropertiesQCOM:                       ProcGetFramebufferTilePropertiesQCOM
GetGeneratedCommandsMemoryRequirementsNV:               ProcGetGeneratedCommandsMemoryRequirementsNV
GetImageDrmFormatModifierPropertiesEXT:                 ProcGetImageDrmFormatModifierPropertiesEXT
GetImageMemoryRequirements:                             ProcGetImageMemoryRequirements
GetImageMemoryRequirements2:                            ProcGetImageMemoryRequirements2
GetImageMemoryRequirements2KHR:                         ProcGetImageMemoryRequirements2KHR
GetImageOpaqueCaptureDescriptorDataEXT:                 ProcGetImageOpaqueCaptureDescriptorDataEXT
GetImageSparseMemoryRequirements:                       ProcGetImageSparseMemoryRequirements
GetImageSparseMemoryRequirements2:                      ProcGetImageSparseMemoryRequirements2
GetImageSparseMemoryRequirements2KHR:                   ProcGetImageSparseMemoryRequirements2KHR
GetImageSubresourceLayout:                              ProcGetImageSubresourceLayout
GetImageSubresourceLayout2EXT:                          ProcGetImageSubresourceLayout2EXT
GetImageViewAddressNVX:                                 ProcGetImageViewAddressNVX
GetImageViewHandleNVX:                                  ProcGetImageViewHandleNVX
GetImageViewOpaqueCaptureDescriptorDataEXT:             ProcGetImageViewOpaqueCaptureDescriptorDataEXT
GetMemoryFdKHR:                                         ProcGetMemoryFdKHR
GetMemoryFdPropertiesKHR:                               ProcGetMemoryFdPropertiesKHR
GetMemoryHostPointerPropertiesEXT:                      ProcGetMemoryHostPointerPropertiesEXT
GetMemoryRemoteAddressNV:                               ProcGetMemoryRemoteAddressNV
GetMemoryWin32HandleKHR:                                ProcGetMemoryWin32HandleKHR
GetMemoryWin32HandleNV:                                 ProcGetMemoryWin32HandleNV
GetMemoryWin32HandlePropertiesKHR:                      ProcGetMemoryWin32HandlePropertiesKHR
GetMicromapBuildSizesEXT:                               ProcGetMicromapBuildSizesEXT
GetPastPresentationTimingGOOGLE:                        ProcGetPastPresentationTimingGOOGLE
GetPerformanceParameterINTEL:                           ProcGetPerformanceParameterINTEL
GetPipelineCacheData:                                   ProcGetPipelineCacheData
GetPipelineExecutableInternalRepresentationsKHR:        ProcGetPipelineExecutableInternalRepresentationsKHR
GetPipelineExecutablePropertiesKHR:                     ProcGetPipelineExecutablePropertiesKHR
GetPipelineExecutableStatisticsKHR:                     ProcGetPipelineExecutableStatisticsKHR
GetPipelinePropertiesEXT:                               ProcGetPipelinePropertiesEXT
GetPrivateData:                                         ProcGetPrivateData
GetPrivateDataEXT:                                      ProcGetPrivateDataEXT
GetQueryPoolResults:                                    ProcGetQueryPoolResults
GetQueueCheckpointData2NV:                              ProcGetQueueCheckpointData2NV
GetQueueCheckpointDataNV:                               ProcGetQueueCheckpointDataNV
GetRayTracingCaptureReplayShaderGroupHandlesKHR:        ProcGetRayTracingCaptureReplayShaderGroupHandlesKHR
GetRayTracingShaderGroupHandlesKHR:                     ProcGetRayTracingShaderGroupHandlesKHR
GetRayTracingShaderGroupHandlesNV:                      ProcGetRayTracingShaderGroupHandlesNV
GetRayTracingShaderGroupStackSizeKHR:                   ProcGetRayTracingShaderGroupStackSizeKHR
GetRefreshCycleDurationGOOGLE:                          ProcGetRefreshCycleDurationGOOGLE
GetRenderAreaGranularity:                               ProcGetRenderAreaGranularity
GetSamplerOpaqueCaptureDescriptorDataEXT:               ProcGetSamplerOpaqueCaptureDescriptorDataEXT
GetSemaphoreCounterValue:                               ProcGetSemaphoreCounterValue
GetSemaphoreCounterValueKHR:                            ProcGetSemaphoreCounterValueKHR
GetSemaphoreFdKHR:                                      ProcGetSemaphoreFdKHR
GetSemaphoreWin32HandleKHR:                             ProcGetSemaphoreWin32HandleKHR
GetShaderBinaryDataEXT:                                 ProcGetShaderBinaryDataEXT
GetShaderInfoAMD:                                       ProcGetShaderInfoAMD
GetShaderModuleCreateInfoIdentifierEXT:                 ProcGetShaderModuleCreateInfoIdentifierEXT
GetShaderModuleIdentifierEXT:                           ProcGetShaderModuleIdentifierEXT
GetSwapchainCounterEXT:                                 ProcGetSwapchainCounterEXT
GetSwapchainImagesKHR:                                  ProcGetSwapchainImagesKHR
GetSwapchainStatusKHR:                                  ProcGetSwapchainStatusKHR
GetValidationCacheDataEXT:                              ProcGetValidationCacheDataEXT
GetVideoSessionMemoryRequirementsKHR:                   ProcGetVideoSessionMemoryRequirementsKHR
ImportFenceFdKHR:                                       ProcImportFenceFdKHR
ImportFenceWin32HandleKHR:                              ProcImportFenceWin32HandleKHR
ImportSemaphoreFdKHR:                                   ProcImportSemaphoreFdKHR
ImportSemaphoreWin32HandleKHR:                          ProcImportSemaphoreWin32HandleKHR
InitializePerformanceApiINTEL:                          ProcInitializePerformanceApiINTEL
InvalidateMappedMemoryRanges:                           ProcInvalidateMappedMemoryRanges
MapMemory:                                              ProcMapMemory
MapMemory2KHR:                                          ProcMapMemory2KHR
MergePipelineCaches:                                    ProcMergePipelineCaches
MergeValidationCachesEXT:                               ProcMergeValidationCachesEXT
QueueBeginDebugUtilsLabelEXT:                           ProcQueueBeginDebugUtilsLabelEXT
QueueBindSparse:                                        ProcQueueBindSparse
QueueEndDebugUtilsLabelEXT:                             ProcQueueEndDebugUtilsLabelEXT
QueueInsertDebugUtilsLabelEXT:                          ProcQueueInsertDebugUtilsLabelEXT
QueuePresentKHR:                                        ProcQueuePresentKHR
QueueSetPerformanceConfigurationINTEL:                  ProcQueueSetPerformanceConfigurationINTEL
QueueSubmit:                                            ProcQueueSubmit
QueueSubmit2:                                           ProcQueueSubmit2
QueueSubmit2KHR:                                        ProcQueueSubmit2KHR
QueueWaitIdle:                                          ProcQueueWaitIdle
RegisterDeviceEventEXT:                                 ProcRegisterDeviceEventEXT
RegisterDisplayEventEXT:                                ProcRegisterDisplayEventEXT
ReleaseFullScreenExclusiveModeEXT:                      ProcReleaseFullScreenExclusiveModeEXT
ReleasePerformanceConfigurationINTEL:                   ProcReleasePerformanceConfigurationINTEL
ReleaseProfilingLockKHR:                                ProcReleaseProfilingLockKHR
ReleaseSwapchainImagesEXT:                              ProcReleaseSwapchainImagesEXT
ResetCommandBuffer:                                     ProcResetCommandBuffer
ResetCommandPool:                                       ProcResetCommandPool
ResetDescriptorPool:                                    ProcResetDescriptorPool
ResetEvent:                                             ProcResetEvent
ResetFences:                                            ProcResetFences
ResetQueryPool:                                         ProcResetQueryPool
ResetQueryPoolEXT:                                      ProcResetQueryPoolEXT
SetDebugUtilsObjectNameEXT:                             ProcSetDebugUtilsObjectNameEXT
SetDebugUtilsObjectTagEXT:                              ProcSetDebugUtilsObjectTagEXT
SetDeviceMemoryPriorityEXT:                             ProcSetDeviceMemoryPriorityEXT
SetEvent:                                               ProcSetEvent
SetHdrMetadataEXT:                                      ProcSetHdrMetadataEXT
SetLocalDimmingAMD:                                     ProcSetLocalDimmingAMD
SetPrivateData:                                         ProcSetPrivateData
SetPrivateDataEXT:                                      ProcSetPrivateDataEXT
SignalSemaphore:                                        ProcSignalSemaphore
SignalSemaphoreKHR:                                     ProcSignalSemaphoreKHR
TrimCommandPool:                                        ProcTrimCommandPool
TrimCommandPoolKHR:                                     ProcTrimCommandPoolKHR
UninitializePerformanceApiINTEL:                        ProcUninitializePerformanceApiINTEL
UnmapMemory:                                            ProcUnmapMemory
UnmapMemory2KHR:                                        ProcUnmapMemory2KHR
UpdateDescriptorSetWithTemplate:                        ProcUpdateDescriptorSetWithTemplate
UpdateDescriptorSetWithTemplateKHR:                     ProcUpdateDescriptorSetWithTemplateKHR
UpdateDescriptorSets:                                   ProcUpdateDescriptorSets
UpdateVideoSessionParametersKHR:                        ProcUpdateVideoSessionParametersKHR
WaitForFences:                                          ProcWaitForFences
WaitForPresentKHR:                                      ProcWaitForPresentKHR
WaitSemaphores:                                         ProcWaitSemaphores
WaitSemaphoresKHR:                                      ProcWaitSemaphoresKHR
WriteAccelerationStructuresPropertiesKHR:               ProcWriteAccelerationStructuresPropertiesKHR
WriteMicromapsPropertiesEXT:                            ProcWriteMicromapsPropertiesEXT

load_proc_addresses_custom :: proc(set_proc_address: SetProcAddressType) {
	// Loader Procedures
	set_proc_address(&CreateInstance,                       "vkCreateInstance")
	set_proc_address(&DebugUtilsMessengerCallbackEXT,       "vkDebugUtilsMessengerCallbackEXT")
	set_proc_address(&DeviceMemoryReportCallbackEXT,        "vkDeviceMemoryReportCallbackEXT")
	set_proc_address(&EnumerateInstanceExtensionProperties, "vkEnumerateInstanceExtensionProperties")
	set_proc_address(&EnumerateInstanceLayerProperties,     "vkEnumerateInstanceLayerProperties")
	set_proc_address(&EnumerateInstanceVersion,             "vkEnumerateInstanceVersion")
	set_proc_address(&GetInstanceProcAddr,                  "vkGetInstanceProcAddr")

	// Instance Procedures
	set_proc_address(&AcquireDrmDisplayEXT,                                            "vkAcquireDrmDisplayEXT")
	set_proc_address(&AcquireWinrtDisplayNV,                                           "vkAcquireWinrtDisplayNV")
	set_proc_address(&CreateDebugReportCallbackEXT,                                    "vkCreateDebugReportCallbackEXT")
	set_proc_address(&CreateDebugUtilsMessengerEXT,                                    "vkCreateDebugUtilsMessengerEXT")
	set_proc_address(&CreateDevice,                                                    "vkCreateDevice")
	set_proc_address(&CreateDisplayModeKHR,                                            "vkCreateDisplayModeKHR")
	set_proc_address(&CreateDisplayPlaneSurfaceKHR,                                    "vkCreateDisplayPlaneSurfaceKHR")
	set_proc_address(&CreateHeadlessSurfaceEXT,                                        "vkCreateHeadlessSurfaceEXT")
	set_proc_address(&CreateIOSSurfaceMVK,                                             "vkCreateIOSSurfaceMVK")
	set_proc_address(&CreateMacOSSurfaceMVK,                                           "vkCreateMacOSSurfaceMVK")
	set_proc_address(&CreateMetalSurfaceEXT,                                           "vkCreateMetalSurfaceEXT")
	set_proc_address(&CreateWaylandSurfaceKHR,                                         "vkCreateWaylandSurfaceKHR")
	set_proc_address(&CreateWin32SurfaceKHR,                                           "vkCreateWin32SurfaceKHR")
	set_proc_address(&DebugReportMessageEXT,                                           "vkDebugReportMessageEXT")
	set_proc_address(&DestroyDebugReportCallbackEXT,                                   "vkDestroyDebugReportCallbackEXT")
	set_proc_address(&DestroyDebugUtilsMessengerEXT,                                   "vkDestroyDebugUtilsMessengerEXT")
	set_proc_address(&DestroyInstance,                                                 "vkDestroyInstance")
	set_proc_address(&DestroySurfaceKHR,                                               "vkDestroySurfaceKHR")
	set_proc_address(&EnumerateDeviceExtensionProperties,                              "vkEnumerateDeviceExtensionProperties")
	set_proc_address(&EnumerateDeviceLayerProperties,                                  "vkEnumerateDeviceLayerProperties")
	set_proc_address(&EnumeratePhysicalDeviceGroups,                                   "vkEnumeratePhysicalDeviceGroups")
	set_proc_address(&EnumeratePhysicalDeviceGroupsKHR,                                "vkEnumeratePhysicalDeviceGroupsKHR")
	set_proc_address(&EnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR,   "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR")
	set_proc_address(&EnumeratePhysicalDevices,                                        "vkEnumeratePhysicalDevices")
	set_proc_address(&GetDisplayModeProperties2KHR,                                    "vkGetDisplayModeProperties2KHR")
	set_proc_address(&GetDisplayModePropertiesKHR,                                     "vkGetDisplayModePropertiesKHR")
	set_proc_address(&GetDisplayPlaneCapabilities2KHR,                                 "vkGetDisplayPlaneCapabilities2KHR")
	set_proc_address(&GetDisplayPlaneCapabilitiesKHR,                                  "vkGetDisplayPlaneCapabilitiesKHR")
	set_proc_address(&GetDisplayPlaneSupportedDisplaysKHR,                             "vkGetDisplayPlaneSupportedDisplaysKHR")
	set_proc_address(&GetDrmDisplayEXT,                                                "vkGetDrmDisplayEXT")
	set_proc_address(&GetInstanceProcAddrLUNARG,                                       "vkGetInstanceProcAddrLUNARG")
	set_proc_address(&GetPhysicalDeviceCalibrateableTimeDomainsEXT,                    "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT")
	set_proc_address(&GetPhysicalDeviceCooperativeMatrixPropertiesNV,                  "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV")
	set_proc_address(&GetPhysicalDeviceDisplayPlaneProperties2KHR,                     "vkGetPhysicalDeviceDisplayPlaneProperties2KHR")
	set_proc_address(&GetPhysicalDeviceDisplayPlanePropertiesKHR,                      "vkGetPhysicalDeviceDisplayPlanePropertiesKHR")
	set_proc_address(&GetPhysicalDeviceDisplayProperties2KHR,                          "vkGetPhysicalDeviceDisplayProperties2KHR")
	set_proc_address(&GetPhysicalDeviceDisplayPropertiesKHR,                           "vkGetPhysicalDeviceDisplayPropertiesKHR")
	set_proc_address(&GetPhysicalDeviceExternalBufferProperties,                       "vkGetPhysicalDeviceExternalBufferProperties")
	set_proc_address(&GetPhysicalDeviceExternalBufferPropertiesKHR,                    "vkGetPhysicalDeviceExternalBufferPropertiesKHR")
	set_proc_address(&GetPhysicalDeviceExternalFenceProperties,                        "vkGetPhysicalDeviceExternalFenceProperties")
	set_proc_address(&GetPhysicalDeviceExternalFencePropertiesKHR,                     "vkGetPhysicalDeviceExternalFencePropertiesKHR")
	set_proc_address(&GetPhysicalDeviceExternalImageFormatPropertiesNV,                "vkGetPhysicalDeviceExternalImageFormatPropertiesNV")
	set_proc_address(&GetPhysicalDeviceExternalSemaphoreProperties,                    "vkGetPhysicalDeviceExternalSemaphoreProperties")
	set_proc_address(&GetPhysicalDeviceExternalSemaphorePropertiesKHR,                 "vkGetPhysicalDeviceExternalSemaphorePropertiesKHR")
	set_proc_address(&GetPhysicalDeviceFeatures,                                       "vkGetPhysicalDeviceFeatures")
	set_proc_address(&GetPhysicalDeviceFeatures2,                                      "vkGetPhysicalDeviceFeatures2")
	set_proc_address(&GetPhysicalDeviceFeatures2KHR,                                   "vkGetPhysicalDeviceFeatures2KHR")
	set_proc_address(&GetPhysicalDeviceFormatProperties,                               "vkGetPhysicalDeviceFormatProperties")
	set_proc_address(&GetPhysicalDeviceFormatProperties2,                              "vkGetPhysicalDeviceFormatProperties2")
	set_proc_address(&GetPhysicalDeviceFormatProperties2KHR,                           "vkGetPhysicalDeviceFormatProperties2KHR")
	set_proc_address(&GetPhysicalDeviceFragmentShadingRatesKHR,                        "vkGetPhysicalDeviceFragmentShadingRatesKHR")
	set_proc_address(&GetPhysicalDeviceImageFormatProperties,                          "vkGetPhysicalDeviceImageFormatProperties")
	set_proc_address(&GetPhysicalDeviceImageFormatProperties2,                         "vkGetPhysicalDeviceImageFormatProperties2")
	set_proc_address(&GetPhysicalDeviceImageFormatProperties2KHR,                      "vkGetPhysicalDeviceImageFormatProperties2KHR")
	set_proc_address(&GetPhysicalDeviceMemoryProperties,                               "vkGetPhysicalDeviceMemoryProperties")
	set_proc_address(&GetPhysicalDeviceMemoryProperties2,                              "vkGetPhysicalDeviceMemoryProperties2")
	set_proc_address(&GetPhysicalDeviceMemoryProperties2KHR,                           "vkGetPhysicalDeviceMemoryProperties2KHR")
	set_proc_address(&GetPhysicalDeviceMultisamplePropertiesEXT,                       "vkGetPhysicalDeviceMultisamplePropertiesEXT")
	set_proc_address(&GetPhysicalDeviceOpticalFlowImageFormatsNV,                      "vkGetPhysicalDeviceOpticalFlowImageFormatsNV")
	set_proc_address(&GetPhysicalDevicePresentRectanglesKHR,                           "vkGetPhysicalDevicePresentRectanglesKHR")
	set_proc_address(&GetPhysicalDeviceProperties,                                     "vkGetPhysicalDeviceProperties")
	set_proc_address(&GetPhysicalDeviceProperties2,                                    "vkGetPhysicalDeviceProperties2")
	set_proc_address(&GetPhysicalDeviceProperties2KHR,                                 "vkGetPhysicalDeviceProperties2KHR")
	set_proc_address(&GetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR,           "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR")
	set_proc_address(&GetPhysicalDeviceQueueFamilyProperties,                          "vkGetPhysicalDeviceQueueFamilyProperties")
	set_proc_address(&GetPhysicalDeviceQueueFamilyProperties2,                         "vkGetPhysicalDeviceQueueFamilyProperties2")
	set_proc_address(&GetPhysicalDeviceQueueFamilyProperties2KHR,                      "vkGetPhysicalDeviceQueueFamilyProperties2KHR")
	set_proc_address(&GetPhysicalDeviceSparseImageFormatProperties,                    "vkGetPhysicalDeviceSparseImageFormatProperties")
	set_proc_address(&GetPhysicalDeviceSparseImageFormatProperties2,                   "vkGetPhysicalDeviceSparseImageFormatProperties2")
	set_proc_address(&GetPhysicalDeviceSparseImageFormatProperties2KHR,                "vkGetPhysicalDeviceSparseImageFormatProperties2KHR")
	set_proc_address(&GetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV, "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV")
	set_proc_address(&GetPhysicalDeviceSurfaceCapabilities2EXT,                        "vkGetPhysicalDeviceSurfaceCapabilities2EXT")
	set_proc_address(&GetPhysicalDeviceSurfaceCapabilities2KHR,                        "vkGetPhysicalDeviceSurfaceCapabilities2KHR")
	set_proc_address(&GetPhysicalDeviceSurfaceCapabilitiesKHR,                         "vkGetPhysicalDeviceSurfaceCapabilitiesKHR")
	set_proc_address(&GetPhysicalDeviceSurfaceFormats2KHR,                             "vkGetPhysicalDeviceSurfaceFormats2KHR")
	set_proc_address(&GetPhysicalDeviceSurfaceFormatsKHR,                              "vkGetPhysicalDeviceSurfaceFormatsKHR")
	set_proc_address(&GetPhysicalDeviceSurfacePresentModes2EXT,                        "vkGetPhysicalDeviceSurfacePresentModes2EXT")
	set_proc_address(&GetPhysicalDeviceSurfacePresentModesKHR,                         "vkGetPhysicalDeviceSurfacePresentModesKHR")
	set_proc_address(&GetPhysicalDeviceSurfaceSupportKHR,                              "vkGetPhysicalDeviceSurfaceSupportKHR")
	set_proc_address(&GetPhysicalDeviceToolProperties,                                 "vkGetPhysicalDeviceToolProperties")
	set_proc_address(&GetPhysicalDeviceToolPropertiesEXT,                              "vkGetPhysicalDeviceToolPropertiesEXT")
	set_proc_address(&GetPhysicalDeviceVideoCapabilitiesKHR,                           "vkGetPhysicalDeviceVideoCapabilitiesKHR")
	set_proc_address(&GetPhysicalDeviceVideoFormatPropertiesKHR,                       "vkGetPhysicalDeviceVideoFormatPropertiesKHR")
	set_proc_address(&GetPhysicalDeviceWaylandPresentationSupportKHR,                  "vkGetPhysicalDeviceWaylandPresentationSupportKHR")
	set_proc_address(&GetPhysicalDeviceWin32PresentationSupportKHR,                    "vkGetPhysicalDeviceWin32PresentationSupportKHR")
	set_proc_address(&GetWinrtDisplayNV,                                               "vkGetWinrtDisplayNV")
	set_proc_address(&ReleaseDisplayEXT,                                               "vkReleaseDisplayEXT")
	set_proc_address(&SubmitDebugUtilsMessageEXT,                                      "vkSubmitDebugUtilsMessageEXT")

	// Device Procedures
	set_proc_address(&AcquireFullScreenExclusiveModeEXT,                      "vkAcquireFullScreenExclusiveModeEXT")
	set_proc_address(&AcquireNextImage2KHR,                                   "vkAcquireNextImage2KHR")
	set_proc_address(&AcquireNextImageKHR,                                    "vkAcquireNextImageKHR")
	set_proc_address(&AcquirePerformanceConfigurationINTEL,                   "vkAcquirePerformanceConfigurationINTEL")
	set_proc_address(&AcquireProfilingLockKHR,                                "vkAcquireProfilingLockKHR")
	set_proc_address(&AllocateCommandBuffers,                                 "vkAllocateCommandBuffers")
	set_proc_address(&AllocateDescriptorSets,                                 "vkAllocateDescriptorSets")
	set_proc_address(&AllocateMemory,                                         "vkAllocateMemory")
	set_proc_address(&BeginCommandBuffer,                                     "vkBeginCommandBuffer")
	set_proc_address(&BindAccelerationStructureMemoryNV,                      "vkBindAccelerationStructureMemoryNV")
	set_proc_address(&BindBufferMemory,                                       "vkBindBufferMemory")
	set_proc_address(&BindBufferMemory2,                                      "vkBindBufferMemory2")
	set_proc_address(&BindBufferMemory2KHR,                                   "vkBindBufferMemory2KHR")
	set_proc_address(&BindImageMemory,                                        "vkBindImageMemory")
	set_proc_address(&BindImageMemory2,                                       "vkBindImageMemory2")
	set_proc_address(&BindImageMemory2KHR,                                    "vkBindImageMemory2KHR")
	set_proc_address(&BindOpticalFlowSessionImageNV,                          "vkBindOpticalFlowSessionImageNV")
	set_proc_address(&BindVideoSessionMemoryKHR,                              "vkBindVideoSessionMemoryKHR")
	set_proc_address(&BuildAccelerationStructuresKHR,                         "vkBuildAccelerationStructuresKHR")
	set_proc_address(&BuildMicromapsEXT,                                      "vkBuildMicromapsEXT")
	set_proc_address(&CmdBeginConditionalRenderingEXT,                        "vkCmdBeginConditionalRenderingEXT")
	set_proc_address(&CmdBeginDebugUtilsLabelEXT,                             "vkCmdBeginDebugUtilsLabelEXT")
	set_proc_address(&CmdBeginQuery,                                          "vkCmdBeginQuery")
	set_proc_address(&CmdBeginQueryIndexedEXT,                                "vkCmdBeginQueryIndexedEXT")
	set_proc_address(&CmdBeginRenderPass,                                     "vkCmdBeginRenderPass")
	set_proc_address(&CmdBeginRenderPass2,                                    "vkCmdBeginRenderPass2")
	set_proc_address(&CmdBeginRenderPass2KHR,                                 "vkCmdBeginRenderPass2KHR")
	set_proc_address(&CmdBeginRendering,                                      "vkCmdBeginRendering")
	set_proc_address(&CmdBeginRenderingKHR,                                   "vkCmdBeginRenderingKHR")
	set_proc_address(&CmdBeginTransformFeedbackEXT,                           "vkCmdBeginTransformFeedbackEXT")
	set_proc_address(&CmdBeginVideoCodingKHR,                                 "vkCmdBeginVideoCodingKHR")
	set_proc_address(&CmdBindDescriptorBufferEmbeddedSamplersEXT,             "vkCmdBindDescriptorBufferEmbeddedSamplersEXT")
	set_proc_address(&CmdBindDescriptorBuffersEXT,                            "vkCmdBindDescriptorBuffersEXT")
	set_proc_address(&CmdBindDescriptorSets,                                  "vkCmdBindDescriptorSets")
	set_proc_address(&CmdBindIndexBuffer,                                     "vkCmdBindIndexBuffer")
	set_proc_address(&CmdBindInvocationMaskHUAWEI,                            "vkCmdBindInvocationMaskHUAWEI")
	set_proc_address(&CmdBindPipeline,                                        "vkCmdBindPipeline")
	set_proc_address(&CmdBindPipelineShaderGroupNV,                           "vkCmdBindPipelineShaderGroupNV")
	set_proc_address(&CmdBindShadersEXT,                                      "vkCmdBindShadersEXT")
	set_proc_address(&CmdBindShadingRateImageNV,                              "vkCmdBindShadingRateImageNV")
	set_proc_address(&CmdBindTransformFeedbackBuffersEXT,                     "vkCmdBindTransformFeedbackBuffersEXT")
	set_proc_address(&CmdBindVertexBuffers,                                   "vkCmdBindVertexBuffers")
	set_proc_address(&CmdBindVertexBuffers2,                                  "vkCmdBindVertexBuffers2")
	set_proc_address(&CmdBindVertexBuffers2EXT,                               "vkCmdBindVertexBuffers2EXT")
	set_proc_address(&CmdBlitImage,                                           "vkCmdBlitImage")
	set_proc_address(&CmdBlitImage2,                                          "vkCmdBlitImage2")
	set_proc_address(&CmdBlitImage2KHR,                                       "vkCmdBlitImage2KHR")
	set_proc_address(&CmdBuildAccelerationStructureNV,                        "vkCmdBuildAccelerationStructureNV")
	set_proc_address(&CmdBuildAccelerationStructuresIndirectKHR,              "vkCmdBuildAccelerationStructuresIndirectKHR")
	set_proc_address(&CmdBuildAccelerationStructuresKHR,                      "vkCmdBuildAccelerationStructuresKHR")
	set_proc_address(&CmdBuildMicromapsEXT,                                   "vkCmdBuildMicromapsEXT")
	set_proc_address(&CmdClearAttachments,                                    "vkCmdClearAttachments")
	set_proc_address(&CmdClearColorImage,                                     "vkCmdClearColorImage")
	set_proc_address(&CmdClearDepthStencilImage,                              "vkCmdClearDepthStencilImage")
	set_proc_address(&CmdControlVideoCodingKHR,                               "vkCmdControlVideoCodingKHR")
	set_proc_address(&CmdCopyAccelerationStructureKHR,                        "vkCmdCopyAccelerationStructureKHR")
	set_proc_address(&CmdCopyAccelerationStructureNV,                         "vkCmdCopyAccelerationStructureNV")
	set_proc_address(&CmdCopyAccelerationStructureToMemoryKHR,                "vkCmdCopyAccelerationStructureToMemoryKHR")
	set_proc_address(&CmdCopyBuffer,                                          "vkCmdCopyBuffer")
	set_proc_address(&CmdCopyBuffer2,                                         "vkCmdCopyBuffer2")
	set_proc_address(&CmdCopyBuffer2KHR,                                      "vkCmdCopyBuffer2KHR")
	set_proc_address(&CmdCopyBufferToImage,                                   "vkCmdCopyBufferToImage")
	set_proc_address(&CmdCopyBufferToImage2,                                  "vkCmdCopyBufferToImage2")
	set_proc_address(&CmdCopyBufferToImage2KHR,                               "vkCmdCopyBufferToImage2KHR")
	set_proc_address(&CmdCopyImage,                                           "vkCmdCopyImage")
	set_proc_address(&CmdCopyImage2,                                          "vkCmdCopyImage2")
	set_proc_address(&CmdCopyImage2KHR,                                       "vkCmdCopyImage2KHR")
	set_proc_address(&CmdCopyImageToBuffer,                                   "vkCmdCopyImageToBuffer")
	set_proc_address(&CmdCopyImageToBuffer2,                                  "vkCmdCopyImageToBuffer2")
	set_proc_address(&CmdCopyImageToBuffer2KHR,                               "vkCmdCopyImageToBuffer2KHR")
	set_proc_address(&CmdCopyMemoryIndirectNV,                                "vkCmdCopyMemoryIndirectNV")
	set_proc_address(&CmdCopyMemoryToAccelerationStructureKHR,                "vkCmdCopyMemoryToAccelerationStructureKHR")
	set_proc_address(&CmdCopyMemoryToImageIndirectNV,                         "vkCmdCopyMemoryToImageIndirectNV")
	set_proc_address(&CmdCopyMemoryToMicromapEXT,                             "vkCmdCopyMemoryToMicromapEXT")
	set_proc_address(&CmdCopyMicromapEXT,                                     "vkCmdCopyMicromapEXT")
	set_proc_address(&CmdCopyMicromapToMemoryEXT,                             "vkCmdCopyMicromapToMemoryEXT")
	set_proc_address(&CmdCopyQueryPoolResults,                                "vkCmdCopyQueryPoolResults")
	set_proc_address(&CmdCuLaunchKernelNVX,                                   "vkCmdCuLaunchKernelNVX")
	set_proc_address(&CmdDebugMarkerBeginEXT,                                 "vkCmdDebugMarkerBeginEXT")
	set_proc_address(&CmdDebugMarkerEndEXT,                                   "vkCmdDebugMarkerEndEXT")
	set_proc_address(&CmdDebugMarkerInsertEXT,                                "vkCmdDebugMarkerInsertEXT")
	set_proc_address(&CmdDecodeVideoKHR,                                      "vkCmdDecodeVideoKHR")
	set_proc_address(&CmdDecompressMemoryIndirectCountNV,                     "vkCmdDecompressMemoryIndirectCountNV")
	set_proc_address(&CmdDecompressMemoryNV,                                  "vkCmdDecompressMemoryNV")
	set_proc_address(&CmdDispatch,                                            "vkCmdDispatch")
	set_proc_address(&CmdDispatchBase,                                        "vkCmdDispatchBase")
	set_proc_address(&CmdDispatchBaseKHR,                                     "vkCmdDispatchBaseKHR")
	set_proc_address(&CmdDispatchIndirect,                                    "vkCmdDispatchIndirect")
	set_proc_address(&CmdDraw,                                                "vkCmdDraw")
	set_proc_address(&CmdDrawClusterHUAWEI,                                   "vkCmdDrawClusterHUAWEI")
	set_proc_address(&CmdDrawClusterIndirectHUAWEI,                           "vkCmdDrawClusterIndirectHUAWEI")
	set_proc_address(&CmdDrawIndexed,                                         "vkCmdDrawIndexed")
	set_proc_address(&CmdDrawIndexedIndirect,                                 "vkCmdDrawIndexedIndirect")
	set_proc_address(&CmdDrawIndexedIndirectCount,                            "vkCmdDrawIndexedIndirectCount")
	set_proc_address(&CmdDrawIndexedIndirectCountAMD,                         "vkCmdDrawIndexedIndirectCountAMD")
	set_proc_address(&CmdDrawIndexedIndirectCountKHR,                         "vkCmdDrawIndexedIndirectCountKHR")
	set_proc_address(&CmdDrawIndirect,                                        "vkCmdDrawIndirect")
	set_proc_address(&CmdDrawIndirectByteCountEXT,                            "vkCmdDrawIndirectByteCountEXT")
	set_proc_address(&CmdDrawIndirectCount,                                   "vkCmdDrawIndirectCount")
	set_proc_address(&CmdDrawIndirectCountAMD,                                "vkCmdDrawIndirectCountAMD")
	set_proc_address(&CmdDrawIndirectCountKHR,                                "vkCmdDrawIndirectCountKHR")
	set_proc_address(&CmdDrawMeshTasksEXT,                                    "vkCmdDrawMeshTasksEXT")
	set_proc_address(&CmdDrawMeshTasksIndirectCountEXT,                       "vkCmdDrawMeshTasksIndirectCountEXT")
	set_proc_address(&CmdDrawMeshTasksIndirectCountNV,                        "vkCmdDrawMeshTasksIndirectCountNV")
	set_proc_address(&CmdDrawMeshTasksIndirectEXT,                            "vkCmdDrawMeshTasksIndirectEXT")
	set_proc_address(&CmdDrawMeshTasksIndirectNV,                             "vkCmdDrawMeshTasksIndirectNV")
	set_proc_address(&CmdDrawMeshTasksNV,                                     "vkCmdDrawMeshTasksNV")
	set_proc_address(&CmdDrawMultiEXT,                                        "vkCmdDrawMultiEXT")
	set_proc_address(&CmdDrawMultiIndexedEXT,                                 "vkCmdDrawMultiIndexedEXT")
	set_proc_address(&CmdEndConditionalRenderingEXT,                          "vkCmdEndConditionalRenderingEXT")
	set_proc_address(&CmdEndDebugUtilsLabelEXT,                               "vkCmdEndDebugUtilsLabelEXT")
	set_proc_address(&CmdEndQuery,                                            "vkCmdEndQuery")
	set_proc_address(&CmdEndQueryIndexedEXT,                                  "vkCmdEndQueryIndexedEXT")
	set_proc_address(&CmdEndRenderPass,                                       "vkCmdEndRenderPass")
	set_proc_address(&CmdEndRenderPass2,                                      "vkCmdEndRenderPass2")
	set_proc_address(&CmdEndRenderPass2KHR,                                   "vkCmdEndRenderPass2KHR")
	set_proc_address(&CmdEndRendering,                                        "vkCmdEndRendering")
	set_proc_address(&CmdEndRenderingKHR,                                     "vkCmdEndRenderingKHR")
	set_proc_address(&CmdEndTransformFeedbackEXT,                             "vkCmdEndTransformFeedbackEXT")
	set_proc_address(&CmdEndVideoCodingKHR,                                   "vkCmdEndVideoCodingKHR")
	set_proc_address(&CmdExecuteCommands,                                     "vkCmdExecuteCommands")
	set_proc_address(&CmdExecuteGeneratedCommandsNV,                          "vkCmdExecuteGeneratedCommandsNV")
	set_proc_address(&CmdFillBuffer,                                          "vkCmdFillBuffer")
	set_proc_address(&CmdInsertDebugUtilsLabelEXT,                            "vkCmdInsertDebugUtilsLabelEXT")
	set_proc_address(&CmdNextSubpass,                                         "vkCmdNextSubpass")
	set_proc_address(&CmdNextSubpass2,                                        "vkCmdNextSubpass2")
	set_proc_address(&CmdNextSubpass2KHR,                                     "vkCmdNextSubpass2KHR")
	set_proc_address(&CmdOpticalFlowExecuteNV,                                "vkCmdOpticalFlowExecuteNV")
	set_proc_address(&CmdPipelineBarrier,                                     "vkCmdPipelineBarrier")
	set_proc_address(&CmdPipelineBarrier2,                                    "vkCmdPipelineBarrier2")
	set_proc_address(&CmdPipelineBarrier2KHR,                                 "vkCmdPipelineBarrier2KHR")
	set_proc_address(&CmdPreprocessGeneratedCommandsNV,                       "vkCmdPreprocessGeneratedCommandsNV")
	set_proc_address(&CmdPushConstants,                                       "vkCmdPushConstants")
	set_proc_address(&CmdPushDescriptorSetKHR,                                "vkCmdPushDescriptorSetKHR")
	set_proc_address(&CmdPushDescriptorSetWithTemplateKHR,                    "vkCmdPushDescriptorSetWithTemplateKHR")
	set_proc_address(&CmdResetEvent,                                          "vkCmdResetEvent")
	set_proc_address(&CmdResetEvent2,                                         "vkCmdResetEvent2")
	set_proc_address(&CmdResetEvent2KHR,                                      "vkCmdResetEvent2KHR")
	set_proc_address(&CmdResetQueryPool,                                      "vkCmdResetQueryPool")
	set_proc_address(&CmdResolveImage,                                        "vkCmdResolveImage")
	set_proc_address(&CmdResolveImage2,                                       "vkCmdResolveImage2")
	set_proc_address(&CmdResolveImage2KHR,                                    "vkCmdResolveImage2KHR")
	set_proc_address(&CmdSetAlphaToCoverageEnableEXT,                         "vkCmdSetAlphaToCoverageEnableEXT")
	set_proc_address(&CmdSetAlphaToOneEnableEXT,                              "vkCmdSetAlphaToOneEnableEXT")
	set_proc_address(&CmdSetAttachmentFeedbackLoopEnableEXT,                  "vkCmdSetAttachmentFeedbackLoopEnableEXT")
	set_proc_address(&CmdSetBlendConstants,                                   "vkCmdSetBlendConstants")
	set_proc_address(&CmdSetCheckpointNV,                                     "vkCmdSetCheckpointNV")
	set_proc_address(&CmdSetCoarseSampleOrderNV,                              "vkCmdSetCoarseSampleOrderNV")
	set_proc_address(&CmdSetColorBlendAdvancedEXT,                            "vkCmdSetColorBlendAdvancedEXT")
	set_proc_address(&CmdSetColorBlendEnableEXT,                              "vkCmdSetColorBlendEnableEXT")
	set_proc_address(&CmdSetColorBlendEquationEXT,                            "vkCmdSetColorBlendEquationEXT")
	set_proc_address(&CmdSetColorWriteMaskEXT,                                "vkCmdSetColorWriteMaskEXT")
	set_proc_address(&CmdSetConservativeRasterizationModeEXT,                 "vkCmdSetConservativeRasterizationModeEXT")
	set_proc_address(&CmdSetCoverageModulationModeNV,                         "vkCmdSetCoverageModulationModeNV")
	set_proc_address(&CmdSetCoverageModulationTableEnableNV,                  "vkCmdSetCoverageModulationTableEnableNV")
	set_proc_address(&CmdSetCoverageModulationTableNV,                        "vkCmdSetCoverageModulationTableNV")
	set_proc_address(&CmdSetCoverageReductionModeNV,                          "vkCmdSetCoverageReductionModeNV")
	set_proc_address(&CmdSetCoverageToColorEnableNV,                          "vkCmdSetCoverageToColorEnableNV")
	set_proc_address(&CmdSetCoverageToColorLocationNV,                        "vkCmdSetCoverageToColorLocationNV")
	set_proc_address(&CmdSetCullMode,                                         "vkCmdSetCullMode")
	set_proc_address(&CmdSetCullModeEXT,                                      "vkCmdSetCullModeEXT")
	set_proc_address(&CmdSetDepthBias,                                        "vkCmdSetDepthBias")
	set_proc_address(&CmdSetDepthBiasEnable,                                  "vkCmdSetDepthBiasEnable")
	set_proc_address(&CmdSetDepthBiasEnableEXT,                               "vkCmdSetDepthBiasEnableEXT")
	set_proc_address(&CmdSetDepthBounds,                                      "vkCmdSetDepthBounds")
	set_proc_address(&CmdSetDepthBoundsTestEnable,                            "vkCmdSetDepthBoundsTestEnable")
	set_proc_address(&CmdSetDepthBoundsTestEnableEXT,                         "vkCmdSetDepthBoundsTestEnableEXT")
	set_proc_address(&CmdSetDepthClampEnableEXT,                              "vkCmdSetDepthClampEnableEXT")
	set_proc_address(&CmdSetDepthClipEnableEXT,                               "vkCmdSetDepthClipEnableEXT")
	set_proc_address(&CmdSetDepthClipNegativeOneToOneEXT,                     "vkCmdSetDepthClipNegativeOneToOneEXT")
	set_proc_address(&CmdSetDepthCompareOp,                                   "vkCmdSetDepthCompareOp")
	set_proc_address(&CmdSetDepthCompareOpEXT,                                "vkCmdSetDepthCompareOpEXT")
	set_proc_address(&CmdSetDepthTestEnable,                                  "vkCmdSetDepthTestEnable")
	set_proc_address(&CmdSetDepthTestEnableEXT,                               "vkCmdSetDepthTestEnableEXT")
	set_proc_address(&CmdSetDepthWriteEnable,                                 "vkCmdSetDepthWriteEnable")
	set_proc_address(&CmdSetDepthWriteEnableEXT,                              "vkCmdSetDepthWriteEnableEXT")
	set_proc_address(&CmdSetDescriptorBufferOffsetsEXT,                       "vkCmdSetDescriptorBufferOffsetsEXT")
	set_proc_address(&CmdSetDeviceMask,                                       "vkCmdSetDeviceMask")
	set_proc_address(&CmdSetDeviceMaskKHR,                                    "vkCmdSetDeviceMaskKHR")
	set_proc_address(&CmdSetDiscardRectangleEXT,                              "vkCmdSetDiscardRectangleEXT")
	set_proc_address(&CmdSetDiscardRectangleEnableEXT,                        "vkCmdSetDiscardRectangleEnableEXT")
	set_proc_address(&CmdSetDiscardRectangleModeEXT,                          "vkCmdSetDiscardRectangleModeEXT")
	set_proc_address(&CmdSetEvent,                                            "vkCmdSetEvent")
	set_proc_address(&CmdSetEvent2,                                           "vkCmdSetEvent2")
	set_proc_address(&CmdSetEvent2KHR,                                        "vkCmdSetEvent2KHR")
	set_proc_address(&CmdSetExclusiveScissorEnableNV,                         "vkCmdSetExclusiveScissorEnableNV")
	set_proc_address(&CmdSetExclusiveScissorNV,                               "vkCmdSetExclusiveScissorNV")
	set_proc_address(&CmdSetExtraPrimitiveOverestimationSizeEXT,              "vkCmdSetExtraPrimitiveOverestimationSizeEXT")
	set_proc_address(&CmdSetFragmentShadingRateEnumNV,                        "vkCmdSetFragmentShadingRateEnumNV")
	set_proc_address(&CmdSetFragmentShadingRateKHR,                           "vkCmdSetFragmentShadingRateKHR")
	set_proc_address(&CmdSetFrontFace,                                        "vkCmdSetFrontFace")
	set_proc_address(&CmdSetFrontFaceEXT,                                     "vkCmdSetFrontFaceEXT")
	set_proc_address(&CmdSetLineRasterizationModeEXT,                         "vkCmdSetLineRasterizationModeEXT")
	set_proc_address(&CmdSetLineStippleEXT,                                   "vkCmdSetLineStippleEXT")
	set_proc_address(&CmdSetLineStippleEnableEXT,                             "vkCmdSetLineStippleEnableEXT")
	set_proc_address(&CmdSetLineWidth,                                        "vkCmdSetLineWidth")
	set_proc_address(&CmdSetLogicOpEXT,                                       "vkCmdSetLogicOpEXT")
	set_proc_address(&CmdSetLogicOpEnableEXT,                                 "vkCmdSetLogicOpEnableEXT")
	set_proc_address(&CmdSetPatchControlPointsEXT,                            "vkCmdSetPatchControlPointsEXT")
	set_proc_address(&CmdSetPerformanceMarkerINTEL,                           "vkCmdSetPerformanceMarkerINTEL")
	set_proc_address(&CmdSetPerformanceOverrideINTEL,                         "vkCmdSetPerformanceOverrideINTEL")
	set_proc_address(&CmdSetPerformanceStreamMarkerINTEL,                     "vkCmdSetPerformanceStreamMarkerINTEL")
	set_proc_address(&CmdSetPolygonModeEXT,                                   "vkCmdSetPolygonModeEXT")
	set_proc_address(&CmdSetPrimitiveRestartEnable,                           "vkCmdSetPrimitiveRestartEnable")
	set_proc_address(&CmdSetPrimitiveRestartEnableEXT,                        "vkCmdSetPrimitiveRestartEnableEXT")
	set_proc_address(&CmdSetPrimitiveTopology,                                "vkCmdSetPrimitiveTopology")
	set_proc_address(&CmdSetPrimitiveTopologyEXT,                             "vkCmdSetPrimitiveTopologyEXT")
	set_proc_address(&CmdSetProvokingVertexModeEXT,                           "vkCmdSetProvokingVertexModeEXT")
	set_proc_address(&CmdSetRasterizationSamplesEXT,                          "vkCmdSetRasterizationSamplesEXT")
	set_proc_address(&CmdSetRasterizationStreamEXT,                           "vkCmdSetRasterizationStreamEXT")
	set_proc_address(&CmdSetRasterizerDiscardEnable,                          "vkCmdSetRasterizerDiscardEnable")
	set_proc_address(&CmdSetRasterizerDiscardEnableEXT,                       "vkCmdSetRasterizerDiscardEnableEXT")
	set_proc_address(&CmdSetRayTracingPipelineStackSizeKHR,                   "vkCmdSetRayTracingPipelineStackSizeKHR")
	set_proc_address(&CmdSetRepresentativeFragmentTestEnableNV,               "vkCmdSetRepresentativeFragmentTestEnableNV")
	set_proc_address(&CmdSetSampleLocationsEXT,                               "vkCmdSetSampleLocationsEXT")
	set_proc_address(&CmdSetSampleLocationsEnableEXT,                         "vkCmdSetSampleLocationsEnableEXT")
	set_proc_address(&CmdSetSampleMaskEXT,                                    "vkCmdSetSampleMaskEXT")
	set_proc_address(&CmdSetScissor,                                          "vkCmdSetScissor")
	set_proc_address(&CmdSetScissorWithCount,                                 "vkCmdSetScissorWithCount")
	set_proc_address(&CmdSetScissorWithCountEXT,                              "vkCmdSetScissorWithCountEXT")
	set_proc_address(&CmdSetShadingRateImageEnableNV,                         "vkCmdSetShadingRateImageEnableNV")
	set_proc_address(&CmdSetStencilCompareMask,                               "vkCmdSetStencilCompareMask")
	set_proc_address(&CmdSetStencilOp,                                        "vkCmdSetStencilOp")
	set_proc_address(&CmdSetStencilOpEXT,                                     "vkCmdSetStencilOpEXT")
	set_proc_address(&CmdSetStencilReference,                                 "vkCmdSetStencilReference")
	set_proc_address(&CmdSetStencilTestEnable,                                "vkCmdSetStencilTestEnable")
	set_proc_address(&CmdSetStencilTestEnableEXT,                             "vkCmdSetStencilTestEnableEXT")
	set_proc_address(&CmdSetStencilWriteMask,                                 "vkCmdSetStencilWriteMask")
	set_proc_address(&CmdSetTessellationDomainOriginEXT,                      "vkCmdSetTessellationDomainOriginEXT")
	set_proc_address(&CmdSetVertexInputEXT,                                   "vkCmdSetVertexInputEXT")
	set_proc_address(&CmdSetViewport,                                         "vkCmdSetViewport")
	set_proc_address(&CmdSetViewportShadingRatePaletteNV,                     "vkCmdSetViewportShadingRatePaletteNV")
	set_proc_address(&CmdSetViewportSwizzleNV,                                "vkCmdSetViewportSwizzleNV")
	set_proc_address(&CmdSetViewportWScalingEnableNV,                         "vkCmdSetViewportWScalingEnableNV")
	set_proc_address(&CmdSetViewportWScalingNV,                               "vkCmdSetViewportWScalingNV")
	set_proc_address(&CmdSetViewportWithCount,                                "vkCmdSetViewportWithCount")
	set_proc_address(&CmdSetViewportWithCountEXT,                             "vkCmdSetViewportWithCountEXT")
	set_proc_address(&CmdSubpassShadingHUAWEI,                                "vkCmdSubpassShadingHUAWEI")
	set_proc_address(&CmdTraceRaysIndirect2KHR,                               "vkCmdTraceRaysIndirect2KHR")
	set_proc_address(&CmdTraceRaysIndirectKHR,                                "vkCmdTraceRaysIndirectKHR")
	set_proc_address(&CmdTraceRaysKHR,                                        "vkCmdTraceRaysKHR")
	set_proc_address(&CmdTraceRaysNV,                                         "vkCmdTraceRaysNV")
	set_proc_address(&CmdUpdateBuffer,                                        "vkCmdUpdateBuffer")
	set_proc_address(&CmdWaitEvents,                                          "vkCmdWaitEvents")
	set_proc_address(&CmdWaitEvents2,                                         "vkCmdWaitEvents2")
	set_proc_address(&CmdWaitEvents2KHR,                                      "vkCmdWaitEvents2KHR")
	set_proc_address(&CmdWriteAccelerationStructuresPropertiesKHR,            "vkCmdWriteAccelerationStructuresPropertiesKHR")
	set_proc_address(&CmdWriteAccelerationStructuresPropertiesNV,             "vkCmdWriteAccelerationStructuresPropertiesNV")
	set_proc_address(&CmdWriteBufferMarker2AMD,                               "vkCmdWriteBufferMarker2AMD")
	set_proc_address(&CmdWriteBufferMarkerAMD,                                "vkCmdWriteBufferMarkerAMD")
	set_proc_address(&CmdWriteMicromapsPropertiesEXT,                         "vkCmdWriteMicromapsPropertiesEXT")
	set_proc_address(&CmdWriteTimestamp,                                      "vkCmdWriteTimestamp")
	set_proc_address(&CmdWriteTimestamp2,                                     "vkCmdWriteTimestamp2")
	set_proc_address(&CmdWriteTimestamp2KHR,                                  "vkCmdWriteTimestamp2KHR")
	set_proc_address(&CompileDeferredNV,                                      "vkCompileDeferredNV")
	set_proc_address(&CopyAccelerationStructureKHR,                           "vkCopyAccelerationStructureKHR")
	set_proc_address(&CopyAccelerationStructureToMemoryKHR,                   "vkCopyAccelerationStructureToMemoryKHR")
	set_proc_address(&CopyMemoryToAccelerationStructureKHR,                   "vkCopyMemoryToAccelerationStructureKHR")
	set_proc_address(&CopyMemoryToMicromapEXT,                                "vkCopyMemoryToMicromapEXT")
	set_proc_address(&CopyMicromapEXT,                                        "vkCopyMicromapEXT")
	set_proc_address(&CopyMicromapToMemoryEXT,                                "vkCopyMicromapToMemoryEXT")
	set_proc_address(&CreateAccelerationStructureKHR,                         "vkCreateAccelerationStructureKHR")
	set_proc_address(&CreateAccelerationStructureNV,                          "vkCreateAccelerationStructureNV")
	set_proc_address(&CreateBuffer,                                           "vkCreateBuffer")
	set_proc_address(&CreateBufferView,                                       "vkCreateBufferView")
	set_proc_address(&CreateCommandPool,                                      "vkCreateCommandPool")
	set_proc_address(&CreateComputePipelines,                                 "vkCreateComputePipelines")
	set_proc_address(&CreateCuFunctionNVX,                                    "vkCreateCuFunctionNVX")
	set_proc_address(&CreateCuModuleNVX,                                      "vkCreateCuModuleNVX")
	set_proc_address(&CreateDeferredOperationKHR,                             "vkCreateDeferredOperationKHR")
	set_proc_address(&CreateDescriptorPool,                                   "vkCreateDescriptorPool")
	set_proc_address(&CreateDescriptorSetLayout,                              "vkCreateDescriptorSetLayout")
	set_proc_address(&CreateDescriptorUpdateTemplate,                         "vkCreateDescriptorUpdateTemplate")
	set_proc_address(&CreateDescriptorUpdateTemplateKHR,                      "vkCreateDescriptorUpdateTemplateKHR")
	set_proc_address(&CreateEvent,                                            "vkCreateEvent")
	set_proc_address(&CreateFence,                                            "vkCreateFence")
	set_proc_address(&CreateFramebuffer,                                      "vkCreateFramebuffer")
	set_proc_address(&CreateGraphicsPipelines,                                "vkCreateGraphicsPipelines")
	set_proc_address(&CreateImage,                                            "vkCreateImage")
	set_proc_address(&CreateImageView,                                        "vkCreateImageView")
	set_proc_address(&CreateIndirectCommandsLayoutNV,                         "vkCreateIndirectCommandsLayoutNV")
	set_proc_address(&CreateMicromapEXT,                                      "vkCreateMicromapEXT")
	set_proc_address(&CreateOpticalFlowSessionNV,                             "vkCreateOpticalFlowSessionNV")
	set_proc_address(&CreatePipelineCache,                                    "vkCreatePipelineCache")
	set_proc_address(&CreatePipelineLayout,                                   "vkCreatePipelineLayout")
	set_proc_address(&CreatePrivateDataSlot,                                  "vkCreatePrivateDataSlot")
	set_proc_address(&CreatePrivateDataSlotEXT,                               "vkCreatePrivateDataSlotEXT")
	set_proc_address(&CreateQueryPool,                                        "vkCreateQueryPool")
	set_proc_address(&CreateRayTracingPipelinesKHR,                           "vkCreateRayTracingPipelinesKHR")
	set_proc_address(&CreateRayTracingPipelinesNV,                            "vkCreateRayTracingPipelinesNV")
	set_proc_address(&CreateRenderPass,                                       "vkCreateRenderPass")
	set_proc_address(&CreateRenderPass2,                                      "vkCreateRenderPass2")
	set_proc_address(&CreateRenderPass2KHR,                                   "vkCreateRenderPass2KHR")
	set_proc_address(&CreateSampler,                                          "vkCreateSampler")
	set_proc_address(&CreateSamplerYcbcrConversion,                           "vkCreateSamplerYcbcrConversion")
	set_proc_address(&CreateSamplerYcbcrConversionKHR,                        "vkCreateSamplerYcbcrConversionKHR")
	set_proc_address(&CreateSemaphore,                                        "vkCreateSemaphore")
	set_proc_address(&CreateShaderModule,                                     "vkCreateShaderModule")
	set_proc_address(&CreateShadersEXT,                                       "vkCreateShadersEXT")
	set_proc_address(&CreateSharedSwapchainsKHR,                              "vkCreateSharedSwapchainsKHR")
	set_proc_address(&CreateSwapchainKHR,                                     "vkCreateSwapchainKHR")
	set_proc_address(&CreateValidationCacheEXT,                               "vkCreateValidationCacheEXT")
	set_proc_address(&CreateVideoSessionKHR,                                  "vkCreateVideoSessionKHR")
	set_proc_address(&CreateVideoSessionParametersKHR,                        "vkCreateVideoSessionParametersKHR")
	set_proc_address(&DebugMarkerSetObjectNameEXT,                            "vkDebugMarkerSetObjectNameEXT")
	set_proc_address(&DebugMarkerSetObjectTagEXT,                             "vkDebugMarkerSetObjectTagEXT")
	set_proc_address(&DeferredOperationJoinKHR,                               "vkDeferredOperationJoinKHR")
	set_proc_address(&DestroyAccelerationStructureKHR,                        "vkDestroyAccelerationStructureKHR")
	set_proc_address(&DestroyAccelerationStructureNV,                         "vkDestroyAccelerationStructureNV")
	set_proc_address(&DestroyBuffer,                                          "vkDestroyBuffer")
	set_proc_address(&DestroyBufferView,                                      "vkDestroyBufferView")
	set_proc_address(&DestroyCommandPool,                                     "vkDestroyCommandPool")
	set_proc_address(&DestroyCuFunctionNVX,                                   "vkDestroyCuFunctionNVX")
	set_proc_address(&DestroyCuModuleNVX,                                     "vkDestroyCuModuleNVX")
	set_proc_address(&DestroyDeferredOperationKHR,                            "vkDestroyDeferredOperationKHR")
	set_proc_address(&DestroyDescriptorPool,                                  "vkDestroyDescriptorPool")
	set_proc_address(&DestroyDescriptorSetLayout,                             "vkDestroyDescriptorSetLayout")
	set_proc_address(&DestroyDescriptorUpdateTemplate,                        "vkDestroyDescriptorUpdateTemplate")
	set_proc_address(&DestroyDescriptorUpdateTemplateKHR,                     "vkDestroyDescriptorUpdateTemplateKHR")
	set_proc_address(&DestroyDevice,                                          "vkDestroyDevice")
	set_proc_address(&DestroyEvent,                                           "vkDestroyEvent")
	set_proc_address(&DestroyFence,                                           "vkDestroyFence")
	set_proc_address(&DestroyFramebuffer,                                     "vkDestroyFramebuffer")
	set_proc_address(&DestroyImage,                                           "vkDestroyImage")
	set_proc_address(&DestroyImageView,                                       "vkDestroyImageView")
	set_proc_address(&DestroyIndirectCommandsLayoutNV,                        "vkDestroyIndirectCommandsLayoutNV")
	set_proc_address(&DestroyMicromapEXT,                                     "vkDestroyMicromapEXT")
	set_proc_address(&DestroyOpticalFlowSessionNV,                            "vkDestroyOpticalFlowSessionNV")
	set_proc_address(&DestroyPipeline,                                        "vkDestroyPipeline")
	set_proc_address(&DestroyPipelineCache,                                   "vkDestroyPipelineCache")
	set_proc_address(&DestroyPipelineLayout,                                  "vkDestroyPipelineLayout")
	set_proc_address(&DestroyPrivateDataSlot,                                 "vkDestroyPrivateDataSlot")
	set_proc_address(&DestroyPrivateDataSlotEXT,                              "vkDestroyPrivateDataSlotEXT")
	set_proc_address(&DestroyQueryPool,                                       "vkDestroyQueryPool")
	set_proc_address(&DestroyRenderPass,                                      "vkDestroyRenderPass")
	set_proc_address(&DestroySampler,                                         "vkDestroySampler")
	set_proc_address(&DestroySamplerYcbcrConversion,                          "vkDestroySamplerYcbcrConversion")
	set_proc_address(&DestroySamplerYcbcrConversionKHR,                       "vkDestroySamplerYcbcrConversionKHR")
	set_proc_address(&DestroySemaphore,                                       "vkDestroySemaphore")
	set_proc_address(&DestroyShaderEXT,                                       "vkDestroyShaderEXT")
	set_proc_address(&DestroyShaderModule,                                    "vkDestroyShaderModule")
	set_proc_address(&DestroySwapchainKHR,                                    "vkDestroySwapchainKHR")
	set_proc_address(&DestroyValidationCacheEXT,                              "vkDestroyValidationCacheEXT")
	set_proc_address(&DestroyVideoSessionKHR,                                 "vkDestroyVideoSessionKHR")
	set_proc_address(&DestroyVideoSessionParametersKHR,                       "vkDestroyVideoSessionParametersKHR")
	set_proc_address(&DeviceWaitIdle,                                         "vkDeviceWaitIdle")
	set_proc_address(&DisplayPowerControlEXT,                                 "vkDisplayPowerControlEXT")
	set_proc_address(&EndCommandBuffer,                                       "vkEndCommandBuffer")
	set_proc_address(&ExportMetalObjectsEXT,                                  "vkExportMetalObjectsEXT")
	set_proc_address(&FlushMappedMemoryRanges,                                "vkFlushMappedMemoryRanges")
	set_proc_address(&FreeCommandBuffers,                                     "vkFreeCommandBuffers")
	set_proc_address(&FreeDescriptorSets,                                     "vkFreeDescriptorSets")
	set_proc_address(&FreeMemory,                                             "vkFreeMemory")
	set_proc_address(&GetAccelerationStructureBuildSizesKHR,                  "vkGetAccelerationStructureBuildSizesKHR")
	set_proc_address(&GetAccelerationStructureDeviceAddressKHR,               "vkGetAccelerationStructureDeviceAddressKHR")
	set_proc_address(&GetAccelerationStructureHandleNV,                       "vkGetAccelerationStructureHandleNV")
	set_proc_address(&GetAccelerationStructureMemoryRequirementsNV,           "vkGetAccelerationStructureMemoryRequirementsNV")
	set_proc_address(&GetAccelerationStructureOpaqueCaptureDescriptorDataEXT, "vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT")
	set_proc_address(&GetBufferDeviceAddress,                                 "vkGetBufferDeviceAddress")
	set_proc_address(&GetBufferDeviceAddressEXT,                              "vkGetBufferDeviceAddressEXT")
	set_proc_address(&GetBufferDeviceAddressKHR,                              "vkGetBufferDeviceAddressKHR")
	set_proc_address(&GetBufferMemoryRequirements,                            "vkGetBufferMemoryRequirements")
	set_proc_address(&GetBufferMemoryRequirements2,                           "vkGetBufferMemoryRequirements2")
	set_proc_address(&GetBufferMemoryRequirements2KHR,                        "vkGetBufferMemoryRequirements2KHR")
	set_proc_address(&GetBufferOpaqueCaptureAddress,                          "vkGetBufferOpaqueCaptureAddress")
	set_proc_address(&GetBufferOpaqueCaptureAddressKHR,                       "vkGetBufferOpaqueCaptureAddressKHR")
	set_proc_address(&GetBufferOpaqueCaptureDescriptorDataEXT,                "vkGetBufferOpaqueCaptureDescriptorDataEXT")
	set_proc_address(&GetCalibratedTimestampsEXT,                             "vkGetCalibratedTimestampsEXT")
	set_proc_address(&GetDeferredOperationMaxConcurrencyKHR,                  "vkGetDeferredOperationMaxConcurrencyKHR")
	set_proc_address(&GetDeferredOperationResultKHR,                          "vkGetDeferredOperationResultKHR")
	set_proc_address(&GetDescriptorEXT,                                       "vkGetDescriptorEXT")
	set_proc_address(&GetDescriptorSetHostMappingVALVE,                       "vkGetDescriptorSetHostMappingVALVE")
	set_proc_address(&GetDescriptorSetLayoutBindingOffsetEXT,                 "vkGetDescriptorSetLayoutBindingOffsetEXT")
	set_proc_address(&GetDescriptorSetLayoutHostMappingInfoVALVE,             "vkGetDescriptorSetLayoutHostMappingInfoVALVE")
	set_proc_address(&GetDescriptorSetLayoutSizeEXT,                          "vkGetDescriptorSetLayoutSizeEXT")
	set_proc_address(&GetDescriptorSetLayoutSupport,                          "vkGetDescriptorSetLayoutSupport")
	set_proc_address(&GetDescriptorSetLayoutSupportKHR,                       "vkGetDescriptorSetLayoutSupportKHR")
	set_proc_address(&GetDeviceAccelerationStructureCompatibilityKHR,         "vkGetDeviceAccelerationStructureCompatibilityKHR")
	set_proc_address(&GetDeviceBufferMemoryRequirements,                      "vkGetDeviceBufferMemoryRequirements")
	set_proc_address(&GetDeviceBufferMemoryRequirementsKHR,                   "vkGetDeviceBufferMemoryRequirementsKHR")
	set_proc_address(&GetDeviceFaultInfoEXT,                                  "vkGetDeviceFaultInfoEXT")
	set_proc_address(&GetDeviceGroupPeerMemoryFeatures,                       "vkGetDeviceGroupPeerMemoryFeatures")
	set_proc_address(&GetDeviceGroupPeerMemoryFeaturesKHR,                    "vkGetDeviceGroupPeerMemoryFeaturesKHR")
	set_proc_address(&GetDeviceGroupPresentCapabilitiesKHR,                   "vkGetDeviceGroupPresentCapabilitiesKHR")
	set_proc_address(&GetDeviceGroupSurfacePresentModes2EXT,                  "vkGetDeviceGroupSurfacePresentModes2EXT")
	set_proc_address(&GetDeviceGroupSurfacePresentModesKHR,                   "vkGetDeviceGroupSurfacePresentModesKHR")
	set_proc_address(&GetDeviceImageMemoryRequirements,                       "vkGetDeviceImageMemoryRequirements")
	set_proc_address(&GetDeviceImageMemoryRequirementsKHR,                    "vkGetDeviceImageMemoryRequirementsKHR")
	set_proc_address(&GetDeviceImageSparseMemoryRequirements,                 "vkGetDeviceImageSparseMemoryRequirements")
	set_proc_address(&GetDeviceImageSparseMemoryRequirementsKHR,              "vkGetDeviceImageSparseMemoryRequirementsKHR")
	set_proc_address(&GetDeviceMemoryCommitment,                              "vkGetDeviceMemoryCommitment")
	set_proc_address(&GetDeviceMemoryOpaqueCaptureAddress,                    "vkGetDeviceMemoryOpaqueCaptureAddress")
	set_proc_address(&GetDeviceMemoryOpaqueCaptureAddressKHR,                 "vkGetDeviceMemoryOpaqueCaptureAddressKHR")
	set_proc_address(&GetDeviceMicromapCompatibilityEXT,                      "vkGetDeviceMicromapCompatibilityEXT")
	set_proc_address(&GetDeviceProcAddr,                                      "vkGetDeviceProcAddr")
	set_proc_address(&GetDeviceQueue,                                         "vkGetDeviceQueue")
	set_proc_address(&GetDeviceQueue2,                                        "vkGetDeviceQueue2")
	set_proc_address(&GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI,          "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI")
	set_proc_address(&GetDynamicRenderingTilePropertiesQCOM,                  "vkGetDynamicRenderingTilePropertiesQCOM")
	set_proc_address(&GetEventStatus,                                         "vkGetEventStatus")
	set_proc_address(&GetFenceFdKHR,                                          "vkGetFenceFdKHR")
	set_proc_address(&GetFenceStatus,                                         "vkGetFenceStatus")
	set_proc_address(&GetFenceWin32HandleKHR,                                 "vkGetFenceWin32HandleKHR")
	set_proc_address(&GetFramebufferTilePropertiesQCOM,                       "vkGetFramebufferTilePropertiesQCOM")
	set_proc_address(&GetGeneratedCommandsMemoryRequirementsNV,               "vkGetGeneratedCommandsMemoryRequirementsNV")
	set_proc_address(&GetImageDrmFormatModifierPropertiesEXT,                 "vkGetImageDrmFormatModifierPropertiesEXT")
	set_proc_address(&GetImageMemoryRequirements,                             "vkGetImageMemoryRequirements")
	set_proc_address(&GetImageMemoryRequirements2,                            "vkGetImageMemoryRequirements2")
	set_proc_address(&GetImageMemoryRequirements2KHR,                         "vkGetImageMemoryRequirements2KHR")
	set_proc_address(&GetImageOpaqueCaptureDescriptorDataEXT,                 "vkGetImageOpaqueCaptureDescriptorDataEXT")
	set_proc_address(&GetImageSparseMemoryRequirements,                       "vkGetImageSparseMemoryRequirements")
	set_proc_address(&GetImageSparseMemoryRequirements2,                      "vkGetImageSparseMemoryRequirements2")
	set_proc_address(&GetImageSparseMemoryRequirements2KHR,                   "vkGetImageSparseMemoryRequirements2KHR")
	set_proc_address(&GetImageSubresourceLayout,                              "vkGetImageSubresourceLayout")
	set_proc_address(&GetImageSubresourceLayout2EXT,                          "vkGetImageSubresourceLayout2EXT")
	set_proc_address(&GetImageViewAddressNVX,                                 "vkGetImageViewAddressNVX")
	set_proc_address(&GetImageViewHandleNVX,                                  "vkGetImageViewHandleNVX")
	set_proc_address(&GetImageViewOpaqueCaptureDescriptorDataEXT,             "vkGetImageViewOpaqueCaptureDescriptorDataEXT")
	set_proc_address(&GetMemoryFdKHR,                                         "vkGetMemoryFdKHR")
	set_proc_address(&GetMemoryFdPropertiesKHR,                               "vkGetMemoryFdPropertiesKHR")
	set_proc_address(&GetMemoryHostPointerPropertiesEXT,                      "vkGetMemoryHostPointerPropertiesEXT")
	set_proc_address(&GetMemoryRemoteAddressNV,                               "vkGetMemoryRemoteAddressNV")
	set_proc_address(&GetMemoryWin32HandleKHR,                                "vkGetMemoryWin32HandleKHR")
	set_proc_address(&GetMemoryWin32HandleNV,                                 "vkGetMemoryWin32HandleNV")
	set_proc_address(&GetMemoryWin32HandlePropertiesKHR,                      "vkGetMemoryWin32HandlePropertiesKHR")
	set_proc_address(&GetMicromapBuildSizesEXT,                               "vkGetMicromapBuildSizesEXT")
	set_proc_address(&GetPastPresentationTimingGOOGLE,                        "vkGetPastPresentationTimingGOOGLE")
	set_proc_address(&GetPerformanceParameterINTEL,                           "vkGetPerformanceParameterINTEL")
	set_proc_address(&GetPipelineCacheData,                                   "vkGetPipelineCacheData")
	set_proc_address(&GetPipelineExecutableInternalRepresentationsKHR,        "vkGetPipelineExecutableInternalRepresentationsKHR")
	set_proc_address(&GetPipelineExecutablePropertiesKHR,                     "vkGetPipelineExecutablePropertiesKHR")
	set_proc_address(&GetPipelineExecutableStatisticsKHR,                     "vkGetPipelineExecutableStatisticsKHR")
	set_proc_address(&GetPipelinePropertiesEXT,                               "vkGetPipelinePropertiesEXT")
	set_proc_address(&GetPrivateData,                                         "vkGetPrivateData")
	set_proc_address(&GetPrivateDataEXT,                                      "vkGetPrivateDataEXT")
	set_proc_address(&GetQueryPoolResults,                                    "vkGetQueryPoolResults")
	set_proc_address(&GetQueueCheckpointData2NV,                              "vkGetQueueCheckpointData2NV")
	set_proc_address(&GetQueueCheckpointDataNV,                               "vkGetQueueCheckpointDataNV")
	set_proc_address(&GetRayTracingCaptureReplayShaderGroupHandlesKHR,        "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR")
	set_proc_address(&GetRayTracingShaderGroupHandlesKHR,                     "vkGetRayTracingShaderGroupHandlesKHR")
	set_proc_address(&GetRayTracingShaderGroupHandlesNV,                      "vkGetRayTracingShaderGroupHandlesNV")
	set_proc_address(&GetRayTracingShaderGroupStackSizeKHR,                   "vkGetRayTracingShaderGroupStackSizeKHR")
	set_proc_address(&GetRefreshCycleDurationGOOGLE,                          "vkGetRefreshCycleDurationGOOGLE")
	set_proc_address(&GetRenderAreaGranularity,                               "vkGetRenderAreaGranularity")
	set_proc_address(&GetSamplerOpaqueCaptureDescriptorDataEXT,               "vkGetSamplerOpaqueCaptureDescriptorDataEXT")
	set_proc_address(&GetSemaphoreCounterValue,                               "vkGetSemaphoreCounterValue")
	set_proc_address(&GetSemaphoreCounterValueKHR,                            "vkGetSemaphoreCounterValueKHR")
	set_proc_address(&GetSemaphoreFdKHR,                                      "vkGetSemaphoreFdKHR")
	set_proc_address(&GetSemaphoreWin32HandleKHR,                             "vkGetSemaphoreWin32HandleKHR")
	set_proc_address(&GetShaderBinaryDataEXT,                                 "vkGetShaderBinaryDataEXT")
	set_proc_address(&GetShaderInfoAMD,                                       "vkGetShaderInfoAMD")
	set_proc_address(&GetShaderModuleCreateInfoIdentifierEXT,                 "vkGetShaderModuleCreateInfoIdentifierEXT")
	set_proc_address(&GetShaderModuleIdentifierEXT,                           "vkGetShaderModuleIdentifierEXT")
	set_proc_address(&GetSwapchainCounterEXT,                                 "vkGetSwapchainCounterEXT")
	set_proc_address(&GetSwapchainImagesKHR,                                  "vkGetSwapchainImagesKHR")
	set_proc_address(&GetSwapchainStatusKHR,                                  "vkGetSwapchainStatusKHR")
	set_proc_address(&GetValidationCacheDataEXT,                              "vkGetValidationCacheDataEXT")
	set_proc_address(&GetVideoSessionMemoryRequirementsKHR,                   "vkGetVideoSessionMemoryRequirementsKHR")
	set_proc_address(&ImportFenceFdKHR,                                       "vkImportFenceFdKHR")
	set_proc_address(&ImportFenceWin32HandleKHR,                              "vkImportFenceWin32HandleKHR")
	set_proc_address(&ImportSemaphoreFdKHR,                                   "vkImportSemaphoreFdKHR")
	set_proc_address(&ImportSemaphoreWin32HandleKHR,                          "vkImportSemaphoreWin32HandleKHR")
	set_proc_address(&InitializePerformanceApiINTEL,                          "vkInitializePerformanceApiINTEL")
	set_proc_address(&InvalidateMappedMemoryRanges,                           "vkInvalidateMappedMemoryRanges")
	set_proc_address(&MapMemory,                                              "vkMapMemory")
	set_proc_address(&MapMemory2KHR,                                          "vkMapMemory2KHR")
	set_proc_address(&MergePipelineCaches,                                    "vkMergePipelineCaches")
	set_proc_address(&MergeValidationCachesEXT,                               "vkMergeValidationCachesEXT")
	set_proc_address(&QueueBeginDebugUtilsLabelEXT,                           "vkQueueBeginDebugUtilsLabelEXT")
	set_proc_address(&QueueBindSparse,                                        "vkQueueBindSparse")
	set_proc_address(&QueueEndDebugUtilsLabelEXT,                             "vkQueueEndDebugUtilsLabelEXT")
	set_proc_address(&QueueInsertDebugUtilsLabelEXT,                          "vkQueueInsertDebugUtilsLabelEXT")
	set_proc_address(&QueuePresentKHR,                                        "vkQueuePresentKHR")
	set_proc_address(&QueueSetPerformanceConfigurationINTEL,                  "vkQueueSetPerformanceConfigurationINTEL")
	set_proc_address(&QueueSubmit,                                            "vkQueueSubmit")
	set_proc_address(&QueueSubmit2,                                           "vkQueueSubmit2")
	set_proc_address(&QueueSubmit2KHR,                                        "vkQueueSubmit2KHR")
	set_proc_address(&QueueWaitIdle,                                          "vkQueueWaitIdle")
	set_proc_address(&RegisterDeviceEventEXT,                                 "vkRegisterDeviceEventEXT")
	set_proc_address(&RegisterDisplayEventEXT,                                "vkRegisterDisplayEventEXT")
	set_proc_address(&ReleaseFullScreenExclusiveModeEXT,                      "vkReleaseFullScreenExclusiveModeEXT")
	set_proc_address(&ReleasePerformanceConfigurationINTEL,                   "vkReleasePerformanceConfigurationINTEL")
	set_proc_address(&ReleaseProfilingLockKHR,                                "vkReleaseProfilingLockKHR")
	set_proc_address(&ReleaseSwapchainImagesEXT,                              "vkReleaseSwapchainImagesEXT")
	set_proc_address(&ResetCommandBuffer,                                     "vkResetCommandBuffer")
	set_proc_address(&ResetCommandPool,                                       "vkResetCommandPool")
	set_proc_address(&ResetDescriptorPool,                                    "vkResetDescriptorPool")
	set_proc_address(&ResetEvent,                                             "vkResetEvent")
	set_proc_address(&ResetFences,                                            "vkResetFences")
	set_proc_address(&ResetQueryPool,                                         "vkResetQueryPool")
	set_proc_address(&ResetQueryPoolEXT,                                      "vkResetQueryPoolEXT")
	set_proc_address(&SetDebugUtilsObjectNameEXT,                             "vkSetDebugUtilsObjectNameEXT")
	set_proc_address(&SetDebugUtilsObjectTagEXT,                              "vkSetDebugUtilsObjectTagEXT")
	set_proc_address(&SetDeviceMemoryPriorityEXT,                             "vkSetDeviceMemoryPriorityEXT")
	set_proc_address(&SetEvent,                                               "vkSetEvent")
	set_proc_address(&SetHdrMetadataEXT,                                      "vkSetHdrMetadataEXT")
	set_proc_address(&SetLocalDimmingAMD,                                     "vkSetLocalDimmingAMD")
	set_proc_address(&SetPrivateData,                                         "vkSetPrivateData")
	set_proc_address(&SetPrivateDataEXT,                                      "vkSetPrivateDataEXT")
	set_proc_address(&SignalSemaphore,                                        "vkSignalSemaphore")
	set_proc_address(&SignalSemaphoreKHR,                                     "vkSignalSemaphoreKHR")
	set_proc_address(&TrimCommandPool,                                        "vkTrimCommandPool")
	set_proc_address(&TrimCommandPoolKHR,                                     "vkTrimCommandPoolKHR")
	set_proc_address(&UninitializePerformanceApiINTEL,                        "vkUninitializePerformanceApiINTEL")
	set_proc_address(&UnmapMemory,                                            "vkUnmapMemory")
	set_proc_address(&UnmapMemory2KHR,                                        "vkUnmapMemory2KHR")
	set_proc_address(&UpdateDescriptorSetWithTemplate,                        "vkUpdateDescriptorSetWithTemplate")
	set_proc_address(&UpdateDescriptorSetWithTemplateKHR,                     "vkUpdateDescriptorSetWithTemplateKHR")
	set_proc_address(&UpdateDescriptorSets,                                   "vkUpdateDescriptorSets")
	set_proc_address(&UpdateVideoSessionParametersKHR,                        "vkUpdateVideoSessionParametersKHR")
	set_proc_address(&WaitForFences,                                          "vkWaitForFences")
	set_proc_address(&WaitForPresentKHR,                                      "vkWaitForPresentKHR")
	set_proc_address(&WaitSemaphores,                                         "vkWaitSemaphores")
	set_proc_address(&WaitSemaphoresKHR,                                      "vkWaitSemaphoresKHR")
	set_proc_address(&WriteAccelerationStructuresPropertiesKHR,               "vkWriteAccelerationStructuresPropertiesKHR")
	set_proc_address(&WriteMicromapsPropertiesEXT,                            "vkWriteMicromapsPropertiesEXT")

}

// Device Procedure VTable
Device_VTable :: struct {
	AcquireFullScreenExclusiveModeEXT:                      ProcAcquireFullScreenExclusiveModeEXT,
	AcquireNextImage2KHR:                                   ProcAcquireNextImage2KHR,
	AcquireNextImageKHR:                                    ProcAcquireNextImageKHR,
	AcquirePerformanceConfigurationINTEL:                   ProcAcquirePerformanceConfigurationINTEL,
	AcquireProfilingLockKHR:                                ProcAcquireProfilingLockKHR,
	AllocateCommandBuffers:                                 ProcAllocateCommandBuffers,
	AllocateDescriptorSets:                                 ProcAllocateDescriptorSets,
	AllocateMemory:                                         ProcAllocateMemory,
	BeginCommandBuffer:                                     ProcBeginCommandBuffer,
	BindAccelerationStructureMemoryNV:                      ProcBindAccelerationStructureMemoryNV,
	BindBufferMemory:                                       ProcBindBufferMemory,
	BindBufferMemory2:                                      ProcBindBufferMemory2,
	BindBufferMemory2KHR:                                   ProcBindBufferMemory2KHR,
	BindImageMemory:                                        ProcBindImageMemory,
	BindImageMemory2:                                       ProcBindImageMemory2,
	BindImageMemory2KHR:                                    ProcBindImageMemory2KHR,
	BindOpticalFlowSessionImageNV:                          ProcBindOpticalFlowSessionImageNV,
	BindVideoSessionMemoryKHR:                              ProcBindVideoSessionMemoryKHR,
	BuildAccelerationStructuresKHR:                         ProcBuildAccelerationStructuresKHR,
	BuildMicromapsEXT:                                      ProcBuildMicromapsEXT,
	CmdBeginConditionalRenderingEXT:                        ProcCmdBeginConditionalRenderingEXT,
	CmdBeginDebugUtilsLabelEXT:                             ProcCmdBeginDebugUtilsLabelEXT,
	CmdBeginQuery:                                          ProcCmdBeginQuery,
	CmdBeginQueryIndexedEXT:                                ProcCmdBeginQueryIndexedEXT,
	CmdBeginRenderPass:                                     ProcCmdBeginRenderPass,
	CmdBeginRenderPass2:                                    ProcCmdBeginRenderPass2,
	CmdBeginRenderPass2KHR:                                 ProcCmdBeginRenderPass2KHR,
	CmdBeginRendering:                                      ProcCmdBeginRendering,
	CmdBeginRenderingKHR:                                   ProcCmdBeginRenderingKHR,
	CmdBeginTransformFeedbackEXT:                           ProcCmdBeginTransformFeedbackEXT,
	CmdBeginVideoCodingKHR:                                 ProcCmdBeginVideoCodingKHR,
	CmdBindDescriptorBufferEmbeddedSamplersEXT:             ProcCmdBindDescriptorBufferEmbeddedSamplersEXT,
	CmdBindDescriptorBuffersEXT:                            ProcCmdBindDescriptorBuffersEXT,
	CmdBindDescriptorSets:                                  ProcCmdBindDescriptorSets,
	CmdBindIndexBuffer:                                     ProcCmdBindIndexBuffer,
	CmdBindInvocationMaskHUAWEI:                            ProcCmdBindInvocationMaskHUAWEI,
	CmdBindPipeline:                                        ProcCmdBindPipeline,
	CmdBindPipelineShaderGroupNV:                           ProcCmdBindPipelineShaderGroupNV,
	CmdBindShadersEXT:                                      ProcCmdBindShadersEXT,
	CmdBindShadingRateImageNV:                              ProcCmdBindShadingRateImageNV,
	CmdBindTransformFeedbackBuffersEXT:                     ProcCmdBindTransformFeedbackBuffersEXT,
	CmdBindVertexBuffers:                                   ProcCmdBindVertexBuffers,
	CmdBindVertexBuffers2:                                  ProcCmdBindVertexBuffers2,
	CmdBindVertexBuffers2EXT:                               ProcCmdBindVertexBuffers2EXT,
	CmdBlitImage:                                           ProcCmdBlitImage,
	CmdBlitImage2:                                          ProcCmdBlitImage2,
	CmdBlitImage2KHR:                                       ProcCmdBlitImage2KHR,
	CmdBuildAccelerationStructureNV:                        ProcCmdBuildAccelerationStructureNV,
	CmdBuildAccelerationStructuresIndirectKHR:              ProcCmdBuildAccelerationStructuresIndirectKHR,
	CmdBuildAccelerationStructuresKHR:                      ProcCmdBuildAccelerationStructuresKHR,
	CmdBuildMicromapsEXT:                                   ProcCmdBuildMicromapsEXT,
	CmdClearAttachments:                                    ProcCmdClearAttachments,
	CmdClearColorImage:                                     ProcCmdClearColorImage,
	CmdClearDepthStencilImage:                              ProcCmdClearDepthStencilImage,
	CmdControlVideoCodingKHR:                               ProcCmdControlVideoCodingKHR,
	CmdCopyAccelerationStructureKHR:                        ProcCmdCopyAccelerationStructureKHR,
	CmdCopyAccelerationStructureNV:                         ProcCmdCopyAccelerationStructureNV,
	CmdCopyAccelerationStructureToMemoryKHR:                ProcCmdCopyAccelerationStructureToMemoryKHR,
	CmdCopyBuffer:                                          ProcCmdCopyBuffer,
	CmdCopyBuffer2:                                         ProcCmdCopyBuffer2,
	CmdCopyBuffer2KHR:                                      ProcCmdCopyBuffer2KHR,
	CmdCopyBufferToImage:                                   ProcCmdCopyBufferToImage,
	CmdCopyBufferToImage2:                                  ProcCmdCopyBufferToImage2,
	CmdCopyBufferToImage2KHR:                               ProcCmdCopyBufferToImage2KHR,
	CmdCopyImage:                                           ProcCmdCopyImage,
	CmdCopyImage2:                                          ProcCmdCopyImage2,
	CmdCopyImage2KHR:                                       ProcCmdCopyImage2KHR,
	CmdCopyImageToBuffer:                                   ProcCmdCopyImageToBuffer,
	CmdCopyImageToBuffer2:                                  ProcCmdCopyImageToBuffer2,
	CmdCopyImageToBuffer2KHR:                               ProcCmdCopyImageToBuffer2KHR,
	CmdCopyMemoryIndirectNV:                                ProcCmdCopyMemoryIndirectNV,
	CmdCopyMemoryToAccelerationStructureKHR:                ProcCmdCopyMemoryToAccelerationStructureKHR,
	CmdCopyMemoryToImageIndirectNV:                         ProcCmdCopyMemoryToImageIndirectNV,
	CmdCopyMemoryToMicromapEXT:                             ProcCmdCopyMemoryToMicromapEXT,
	CmdCopyMicromapEXT:                                     ProcCmdCopyMicromapEXT,
	CmdCopyMicromapToMemoryEXT:                             ProcCmdCopyMicromapToMemoryEXT,
	CmdCopyQueryPoolResults:                                ProcCmdCopyQueryPoolResults,
	CmdCuLaunchKernelNVX:                                   ProcCmdCuLaunchKernelNVX,
	CmdDebugMarkerBeginEXT:                                 ProcCmdDebugMarkerBeginEXT,
	CmdDebugMarkerEndEXT:                                   ProcCmdDebugMarkerEndEXT,
	CmdDebugMarkerInsertEXT:                                ProcCmdDebugMarkerInsertEXT,
	CmdDecodeVideoKHR:                                      ProcCmdDecodeVideoKHR,
	CmdDecompressMemoryIndirectCountNV:                     ProcCmdDecompressMemoryIndirectCountNV,
	CmdDecompressMemoryNV:                                  ProcCmdDecompressMemoryNV,
	CmdDispatch:                                            ProcCmdDispatch,
	CmdDispatchBase:                                        ProcCmdDispatchBase,
	CmdDispatchBaseKHR:                                     ProcCmdDispatchBaseKHR,
	CmdDispatchIndirect:                                    ProcCmdDispatchIndirect,
	CmdDraw:                                                ProcCmdDraw,
	CmdDrawClusterHUAWEI:                                   ProcCmdDrawClusterHUAWEI,
	CmdDrawClusterIndirectHUAWEI:                           ProcCmdDrawClusterIndirectHUAWEI,
	CmdDrawIndexed:                                         ProcCmdDrawIndexed,
	CmdDrawIndexedIndirect:                                 ProcCmdDrawIndexedIndirect,
	CmdDrawIndexedIndirectCount:                            ProcCmdDrawIndexedIndirectCount,
	CmdDrawIndexedIndirectCountAMD:                         ProcCmdDrawIndexedIndirectCountAMD,
	CmdDrawIndexedIndirectCountKHR:                         ProcCmdDrawIndexedIndirectCountKHR,
	CmdDrawIndirect:                                        ProcCmdDrawIndirect,
	CmdDrawIndirectByteCountEXT:                            ProcCmdDrawIndirectByteCountEXT,
	CmdDrawIndirectCount:                                   ProcCmdDrawIndirectCount,
	CmdDrawIndirectCountAMD:                                ProcCmdDrawIndirectCountAMD,
	CmdDrawIndirectCountKHR:                                ProcCmdDrawIndirectCountKHR,
	CmdDrawMeshTasksEXT:                                    ProcCmdDrawMeshTasksEXT,
	CmdDrawMeshTasksIndirectCountEXT:                       ProcCmdDrawMeshTasksIndirectCountEXT,
	CmdDrawMeshTasksIndirectCountNV:                        ProcCmdDrawMeshTasksIndirectCountNV,
	CmdDrawMeshTasksIndirectEXT:                            ProcCmdDrawMeshTasksIndirectEXT,
	CmdDrawMeshTasksIndirectNV:                             ProcCmdDrawMeshTasksIndirectNV,
	CmdDrawMeshTasksNV:                                     ProcCmdDrawMeshTasksNV,
	CmdDrawMultiEXT:                                        ProcCmdDrawMultiEXT,
	CmdDrawMultiIndexedEXT:                                 ProcCmdDrawMultiIndexedEXT,
	CmdEndConditionalRenderingEXT:                          ProcCmdEndConditionalRenderingEXT,
	CmdEndDebugUtilsLabelEXT:                               ProcCmdEndDebugUtilsLabelEXT,
	CmdEndQuery:                                            ProcCmdEndQuery,
	CmdEndQueryIndexedEXT:                                  ProcCmdEndQueryIndexedEXT,
	CmdEndRenderPass:                                       ProcCmdEndRenderPass,
	CmdEndRenderPass2:                                      ProcCmdEndRenderPass2,
	CmdEndRenderPass2KHR:                                   ProcCmdEndRenderPass2KHR,
	CmdEndRendering:                                        ProcCmdEndRendering,
	CmdEndRenderingKHR:                                     ProcCmdEndRenderingKHR,
	CmdEndTransformFeedbackEXT:                             ProcCmdEndTransformFeedbackEXT,
	CmdEndVideoCodingKHR:                                   ProcCmdEndVideoCodingKHR,
	CmdExecuteCommands:                                     ProcCmdExecuteCommands,
	CmdExecuteGeneratedCommandsNV:                          ProcCmdExecuteGeneratedCommandsNV,
	CmdFillBuffer:                                          ProcCmdFillBuffer,
	CmdInsertDebugUtilsLabelEXT:                            ProcCmdInsertDebugUtilsLabelEXT,
	CmdNextSubpass:                                         ProcCmdNextSubpass,
	CmdNextSubpass2:                                        ProcCmdNextSubpass2,
	CmdNextSubpass2KHR:                                     ProcCmdNextSubpass2KHR,
	CmdOpticalFlowExecuteNV:                                ProcCmdOpticalFlowExecuteNV,
	CmdPipelineBarrier:                                     ProcCmdPipelineBarrier,
	CmdPipelineBarrier2:                                    ProcCmdPipelineBarrier2,
	CmdPipelineBarrier2KHR:                                 ProcCmdPipelineBarrier2KHR,
	CmdPreprocessGeneratedCommandsNV:                       ProcCmdPreprocessGeneratedCommandsNV,
	CmdPushConstants:                                       ProcCmdPushConstants,
	CmdPushDescriptorSetKHR:                                ProcCmdPushDescriptorSetKHR,
	CmdPushDescriptorSetWithTemplateKHR:                    ProcCmdPushDescriptorSetWithTemplateKHR,
	CmdResetEvent:                                          ProcCmdResetEvent,
	CmdResetEvent2:                                         ProcCmdResetEvent2,
	CmdResetEvent2KHR:                                      ProcCmdResetEvent2KHR,
	CmdResetQueryPool:                                      ProcCmdResetQueryPool,
	CmdResolveImage:                                        ProcCmdResolveImage,
	CmdResolveImage2:                                       ProcCmdResolveImage2,
	CmdResolveImage2KHR:                                    ProcCmdResolveImage2KHR,
	CmdSetAlphaToCoverageEnableEXT:                         ProcCmdSetAlphaToCoverageEnableEXT,
	CmdSetAlphaToOneEnableEXT:                              ProcCmdSetAlphaToOneEnableEXT,
	CmdSetAttachmentFeedbackLoopEnableEXT:                  ProcCmdSetAttachmentFeedbackLoopEnableEXT,
	CmdSetBlendConstants:                                   ProcCmdSetBlendConstants,
	CmdSetCheckpointNV:                                     ProcCmdSetCheckpointNV,
	CmdSetCoarseSampleOrderNV:                              ProcCmdSetCoarseSampleOrderNV,
	CmdSetColorBlendAdvancedEXT:                            ProcCmdSetColorBlendAdvancedEXT,
	CmdSetColorBlendEnableEXT:                              ProcCmdSetColorBlendEnableEXT,
	CmdSetColorBlendEquationEXT:                            ProcCmdSetColorBlendEquationEXT,
	CmdSetColorWriteMaskEXT:                                ProcCmdSetColorWriteMaskEXT,
	CmdSetConservativeRasterizationModeEXT:                 ProcCmdSetConservativeRasterizationModeEXT,
	CmdSetCoverageModulationModeNV:                         ProcCmdSetCoverageModulationModeNV,
	CmdSetCoverageModulationTableEnableNV:                  ProcCmdSetCoverageModulationTableEnableNV,
	CmdSetCoverageModulationTableNV:                        ProcCmdSetCoverageModulationTableNV,
	CmdSetCoverageReductionModeNV:                          ProcCmdSetCoverageReductionModeNV,
	CmdSetCoverageToColorEnableNV:                          ProcCmdSetCoverageToColorEnableNV,
	CmdSetCoverageToColorLocationNV:                        ProcCmdSetCoverageToColorLocationNV,
	CmdSetCullMode:                                         ProcCmdSetCullMode,
	CmdSetCullModeEXT:                                      ProcCmdSetCullModeEXT,
	CmdSetDepthBias:                                        ProcCmdSetDepthBias,
	CmdSetDepthBiasEnable:                                  ProcCmdSetDepthBiasEnable,
	CmdSetDepthBiasEnableEXT:                               ProcCmdSetDepthBiasEnableEXT,
	CmdSetDepthBounds:                                      ProcCmdSetDepthBounds,
	CmdSetDepthBoundsTestEnable:                            ProcCmdSetDepthBoundsTestEnable,
	CmdSetDepthBoundsTestEnableEXT:                         ProcCmdSetDepthBoundsTestEnableEXT,
	CmdSetDepthClampEnableEXT:                              ProcCmdSetDepthClampEnableEXT,
	CmdSetDepthClipEnableEXT:                               ProcCmdSetDepthClipEnableEXT,
	CmdSetDepthClipNegativeOneToOneEXT:                     ProcCmdSetDepthClipNegativeOneToOneEXT,
	CmdSetDepthCompareOp:                                   ProcCmdSetDepthCompareOp,
	CmdSetDepthCompareOpEXT:                                ProcCmdSetDepthCompareOpEXT,
	CmdSetDepthTestEnable:                                  ProcCmdSetDepthTestEnable,
	CmdSetDepthTestEnableEXT:                               ProcCmdSetDepthTestEnableEXT,
	CmdSetDepthWriteEnable:                                 ProcCmdSetDepthWriteEnable,
	CmdSetDepthWriteEnableEXT:                              ProcCmdSetDepthWriteEnableEXT,
	CmdSetDescriptorBufferOffsetsEXT:                       ProcCmdSetDescriptorBufferOffsetsEXT,
	CmdSetDeviceMask:                                       ProcCmdSetDeviceMask,
	CmdSetDeviceMaskKHR:                                    ProcCmdSetDeviceMaskKHR,
	CmdSetDiscardRectangleEXT:                              ProcCmdSetDiscardRectangleEXT,
	CmdSetDiscardRectangleEnableEXT:                        ProcCmdSetDiscardRectangleEnableEXT,
	CmdSetDiscardRectangleModeEXT:                          ProcCmdSetDiscardRectangleModeEXT,
	CmdSetEvent:                                            ProcCmdSetEvent,
	CmdSetEvent2:                                           ProcCmdSetEvent2,
	CmdSetEvent2KHR:                                        ProcCmdSetEvent2KHR,
	CmdSetExclusiveScissorEnableNV:                         ProcCmdSetExclusiveScissorEnableNV,
	CmdSetExclusiveScissorNV:                               ProcCmdSetExclusiveScissorNV,
	CmdSetExtraPrimitiveOverestimationSizeEXT:              ProcCmdSetExtraPrimitiveOverestimationSizeEXT,
	CmdSetFragmentShadingRateEnumNV:                        ProcCmdSetFragmentShadingRateEnumNV,
	CmdSetFragmentShadingRateKHR:                           ProcCmdSetFragmentShadingRateKHR,
	CmdSetFrontFace:                                        ProcCmdSetFrontFace,
	CmdSetFrontFaceEXT:                                     ProcCmdSetFrontFaceEXT,
	CmdSetLineRasterizationModeEXT:                         ProcCmdSetLineRasterizationModeEXT,
	CmdSetLineStippleEXT:                                   ProcCmdSetLineStippleEXT,
	CmdSetLineStippleEnableEXT:                             ProcCmdSetLineStippleEnableEXT,
	CmdSetLineWidth:                                        ProcCmdSetLineWidth,
	CmdSetLogicOpEXT:                                       ProcCmdSetLogicOpEXT,
	CmdSetLogicOpEnableEXT:                                 ProcCmdSetLogicOpEnableEXT,
	CmdSetPatchControlPointsEXT:                            ProcCmdSetPatchControlPointsEXT,
	CmdSetPerformanceMarkerINTEL:                           ProcCmdSetPerformanceMarkerINTEL,
	CmdSetPerformanceOverrideINTEL:                         ProcCmdSetPerformanceOverrideINTEL,
	CmdSetPerformanceStreamMarkerINTEL:                     ProcCmdSetPerformanceStreamMarkerINTEL,
	CmdSetPolygonModeEXT:                                   ProcCmdSetPolygonModeEXT,
	CmdSetPrimitiveRestartEnable:                           ProcCmdSetPrimitiveRestartEnable,
	CmdSetPrimitiveRestartEnableEXT:                        ProcCmdSetPrimitiveRestartEnableEXT,
	CmdSetPrimitiveTopology:                                ProcCmdSetPrimitiveTopology,
	CmdSetPrimitiveTopologyEXT:                             ProcCmdSetPrimitiveTopologyEXT,
	CmdSetProvokingVertexModeEXT:                           ProcCmdSetProvokingVertexModeEXT,
	CmdSetRasterizationSamplesEXT:                          ProcCmdSetRasterizationSamplesEXT,
	CmdSetRasterizationStreamEXT:                           ProcCmdSetRasterizationStreamEXT,
	CmdSetRasterizerDiscardEnable:                          ProcCmdSetRasterizerDiscardEnable,
	CmdSetRasterizerDiscardEnableEXT:                       ProcCmdSetRasterizerDiscardEnableEXT,
	CmdSetRayTracingPipelineStackSizeKHR:                   ProcCmdSetRayTracingPipelineStackSizeKHR,
	CmdSetRepresentativeFragmentTestEnableNV:               ProcCmdSetRepresentativeFragmentTestEnableNV,
	CmdSetSampleLocationsEXT:                               ProcCmdSetSampleLocationsEXT,
	CmdSetSampleLocationsEnableEXT:                         ProcCmdSetSampleLocationsEnableEXT,
	CmdSetSampleMaskEXT:                                    ProcCmdSetSampleMaskEXT,
	CmdSetScissor:                                          ProcCmdSetScissor,
	CmdSetScissorWithCount:                                 ProcCmdSetScissorWithCount,
	CmdSetScissorWithCountEXT:                              ProcCmdSetScissorWithCountEXT,
	CmdSetShadingRateImageEnableNV:                         ProcCmdSetShadingRateImageEnableNV,
	CmdSetStencilCompareMask:                               ProcCmdSetStencilCompareMask,
	CmdSetStencilOp:                                        ProcCmdSetStencilOp,
	CmdSetStencilOpEXT:                                     ProcCmdSetStencilOpEXT,
	CmdSetStencilReference:                                 ProcCmdSetStencilReference,
	CmdSetStencilTestEnable:                                ProcCmdSetStencilTestEnable,
	CmdSetStencilTestEnableEXT:                             ProcCmdSetStencilTestEnableEXT,
	CmdSetStencilWriteMask:                                 ProcCmdSetStencilWriteMask,
	CmdSetTessellationDomainOriginEXT:                      ProcCmdSetTessellationDomainOriginEXT,
	CmdSetVertexInputEXT:                                   ProcCmdSetVertexInputEXT,
	CmdSetViewport:                                         ProcCmdSetViewport,
	CmdSetViewportShadingRatePaletteNV:                     ProcCmdSetViewportShadingRatePaletteNV,
	CmdSetViewportSwizzleNV:                                ProcCmdSetViewportSwizzleNV,
	CmdSetViewportWScalingEnableNV:                         ProcCmdSetViewportWScalingEnableNV,
	CmdSetViewportWScalingNV:                               ProcCmdSetViewportWScalingNV,
	CmdSetViewportWithCount:                                ProcCmdSetViewportWithCount,
	CmdSetViewportWithCountEXT:                             ProcCmdSetViewportWithCountEXT,
	CmdSubpassShadingHUAWEI:                                ProcCmdSubpassShadingHUAWEI,
	CmdTraceRaysIndirect2KHR:                               ProcCmdTraceRaysIndirect2KHR,
	CmdTraceRaysIndirectKHR:                                ProcCmdTraceRaysIndirectKHR,
	CmdTraceRaysKHR:                                        ProcCmdTraceRaysKHR,
	CmdTraceRaysNV:                                         ProcCmdTraceRaysNV,
	CmdUpdateBuffer:                                        ProcCmdUpdateBuffer,
	CmdWaitEvents:                                          ProcCmdWaitEvents,
	CmdWaitEvents2:                                         ProcCmdWaitEvents2,
	CmdWaitEvents2KHR:                                      ProcCmdWaitEvents2KHR,
	CmdWriteAccelerationStructuresPropertiesKHR:            ProcCmdWriteAccelerationStructuresPropertiesKHR,
	CmdWriteAccelerationStructuresPropertiesNV:             ProcCmdWriteAccelerationStructuresPropertiesNV,
	CmdWriteBufferMarker2AMD:                               ProcCmdWriteBufferMarker2AMD,
	CmdWriteBufferMarkerAMD:                                ProcCmdWriteBufferMarkerAMD,
	CmdWriteMicromapsPropertiesEXT:                         ProcCmdWriteMicromapsPropertiesEXT,
	CmdWriteTimestamp:                                      ProcCmdWriteTimestamp,
	CmdWriteTimestamp2:                                     ProcCmdWriteTimestamp2,
	CmdWriteTimestamp2KHR:                                  ProcCmdWriteTimestamp2KHR,
	CompileDeferredNV:                                      ProcCompileDeferredNV,
	CopyAccelerationStructureKHR:                           ProcCopyAccelerationStructureKHR,
	CopyAccelerationStructureToMemoryKHR:                   ProcCopyAccelerationStructureToMemoryKHR,
	CopyMemoryToAccelerationStructureKHR:                   ProcCopyMemoryToAccelerationStructureKHR,
	CopyMemoryToMicromapEXT:                                ProcCopyMemoryToMicromapEXT,
	CopyMicromapEXT:                                        ProcCopyMicromapEXT,
	CopyMicromapToMemoryEXT:                                ProcCopyMicromapToMemoryEXT,
	CreateAccelerationStructureKHR:                         ProcCreateAccelerationStructureKHR,
	CreateAccelerationStructureNV:                          ProcCreateAccelerationStructureNV,
	CreateBuffer:                                           ProcCreateBuffer,
	CreateBufferView:                                       ProcCreateBufferView,
	CreateCommandPool:                                      ProcCreateCommandPool,
	CreateComputePipelines:                                 ProcCreateComputePipelines,
	CreateCuFunctionNVX:                                    ProcCreateCuFunctionNVX,
	CreateCuModuleNVX:                                      ProcCreateCuModuleNVX,
	CreateDeferredOperationKHR:                             ProcCreateDeferredOperationKHR,
	CreateDescriptorPool:                                   ProcCreateDescriptorPool,
	CreateDescriptorSetLayout:                              ProcCreateDescriptorSetLayout,
	CreateDescriptorUpdateTemplate:                         ProcCreateDescriptorUpdateTemplate,
	CreateDescriptorUpdateTemplateKHR:                      ProcCreateDescriptorUpdateTemplateKHR,
	CreateEvent:                                            ProcCreateEvent,
	CreateFence:                                            ProcCreateFence,
	CreateFramebuffer:                                      ProcCreateFramebuffer,
	CreateGraphicsPipelines:                                ProcCreateGraphicsPipelines,
	CreateImage:                                            ProcCreateImage,
	CreateImageView:                                        ProcCreateImageView,
	CreateIndirectCommandsLayoutNV:                         ProcCreateIndirectCommandsLayoutNV,
	CreateMicromapEXT:                                      ProcCreateMicromapEXT,
	CreateOpticalFlowSessionNV:                             ProcCreateOpticalFlowSessionNV,
	CreatePipelineCache:                                    ProcCreatePipelineCache,
	CreatePipelineLayout:                                   ProcCreatePipelineLayout,
	CreatePrivateDataSlot:                                  ProcCreatePrivateDataSlot,
	CreatePrivateDataSlotEXT:                               ProcCreatePrivateDataSlotEXT,
	CreateQueryPool:                                        ProcCreateQueryPool,
	CreateRayTracingPipelinesKHR:                           ProcCreateRayTracingPipelinesKHR,
	CreateRayTracingPipelinesNV:                            ProcCreateRayTracingPipelinesNV,
	CreateRenderPass:                                       ProcCreateRenderPass,
	CreateRenderPass2:                                      ProcCreateRenderPass2,
	CreateRenderPass2KHR:                                   ProcCreateRenderPass2KHR,
	CreateSampler:                                          ProcCreateSampler,
	CreateSamplerYcbcrConversion:                           ProcCreateSamplerYcbcrConversion,
	CreateSamplerYcbcrConversionKHR:                        ProcCreateSamplerYcbcrConversionKHR,
	CreateSemaphore:                                        ProcCreateSemaphore,
	CreateShaderModule:                                     ProcCreateShaderModule,
	CreateShadersEXT:                                       ProcCreateShadersEXT,
	CreateSharedSwapchainsKHR:                              ProcCreateSharedSwapchainsKHR,
	CreateSwapchainKHR:                                     ProcCreateSwapchainKHR,
	CreateValidationCacheEXT:                               ProcCreateValidationCacheEXT,
	CreateVideoSessionKHR:                                  ProcCreateVideoSessionKHR,
	CreateVideoSessionParametersKHR:                        ProcCreateVideoSessionParametersKHR,
	DebugMarkerSetObjectNameEXT:                            ProcDebugMarkerSetObjectNameEXT,
	DebugMarkerSetObjectTagEXT:                             ProcDebugMarkerSetObjectTagEXT,
	DeferredOperationJoinKHR:                               ProcDeferredOperationJoinKHR,
	DestroyAccelerationStructureKHR:                        ProcDestroyAccelerationStructureKHR,
	DestroyAccelerationStructureNV:                         ProcDestroyAccelerationStructureNV,
	DestroyBuffer:                                          ProcDestroyBuffer,
	DestroyBufferView:                                      ProcDestroyBufferView,
	DestroyCommandPool:                                     ProcDestroyCommandPool,
	DestroyCuFunctionNVX:                                   ProcDestroyCuFunctionNVX,
	DestroyCuModuleNVX:                                     ProcDestroyCuModuleNVX,
	DestroyDeferredOperationKHR:                            ProcDestroyDeferredOperationKHR,
	DestroyDescriptorPool:                                  ProcDestroyDescriptorPool,
	DestroyDescriptorSetLayout:                             ProcDestroyDescriptorSetLayout,
	DestroyDescriptorUpdateTemplate:                        ProcDestroyDescriptorUpdateTemplate,
	DestroyDescriptorUpdateTemplateKHR:                     ProcDestroyDescriptorUpdateTemplateKHR,
	DestroyDevice:                                          ProcDestroyDevice,
	DestroyEvent:                                           ProcDestroyEvent,
	DestroyFence:                                           ProcDestroyFence,
	DestroyFramebuffer:                                     ProcDestroyFramebuffer,
	DestroyImage:                                           ProcDestroyImage,
	DestroyImageView:                                       ProcDestroyImageView,
	DestroyIndirectCommandsLayoutNV:                        ProcDestroyIndirectCommandsLayoutNV,
	DestroyMicromapEXT:                                     ProcDestroyMicromapEXT,
	DestroyOpticalFlowSessionNV:                            ProcDestroyOpticalFlowSessionNV,
	DestroyPipeline:                                        ProcDestroyPipeline,
	DestroyPipelineCache:                                   ProcDestroyPipelineCache,
	DestroyPipelineLayout:                                  ProcDestroyPipelineLayout,
	DestroyPrivateDataSlot:                                 ProcDestroyPrivateDataSlot,
	DestroyPrivateDataSlotEXT:                              ProcDestroyPrivateDataSlotEXT,
	DestroyQueryPool:                                       ProcDestroyQueryPool,
	DestroyRenderPass:                                      ProcDestroyRenderPass,
	DestroySampler:                                         ProcDestroySampler,
	DestroySamplerYcbcrConversion:                          ProcDestroySamplerYcbcrConversion,
	DestroySamplerYcbcrConversionKHR:                       ProcDestroySamplerYcbcrConversionKHR,
	DestroySemaphore:                                       ProcDestroySemaphore,
	DestroyShaderEXT:                                       ProcDestroyShaderEXT,
	DestroyShaderModule:                                    ProcDestroyShaderModule,
	DestroySwapchainKHR:                                    ProcDestroySwapchainKHR,
	DestroyValidationCacheEXT:                              ProcDestroyValidationCacheEXT,
	DestroyVideoSessionKHR:                                 ProcDestroyVideoSessionKHR,
	DestroyVideoSessionParametersKHR:                       ProcDestroyVideoSessionParametersKHR,
	DeviceWaitIdle:                                         ProcDeviceWaitIdle,
	DisplayPowerControlEXT:                                 ProcDisplayPowerControlEXT,
	EndCommandBuffer:                                       ProcEndCommandBuffer,
	ExportMetalObjectsEXT:                                  ProcExportMetalObjectsEXT,
	FlushMappedMemoryRanges:                                ProcFlushMappedMemoryRanges,
	FreeCommandBuffers:                                     ProcFreeCommandBuffers,
	FreeDescriptorSets:                                     ProcFreeDescriptorSets,
	FreeMemory:                                             ProcFreeMemory,
	GetAccelerationStructureBuildSizesKHR:                  ProcGetAccelerationStructureBuildSizesKHR,
	GetAccelerationStructureDeviceAddressKHR:               ProcGetAccelerationStructureDeviceAddressKHR,
	GetAccelerationStructureHandleNV:                       ProcGetAccelerationStructureHandleNV,
	GetAccelerationStructureMemoryRequirementsNV:           ProcGetAccelerationStructureMemoryRequirementsNV,
	GetAccelerationStructureOpaqueCaptureDescriptorDataEXT: ProcGetAccelerationStructureOpaqueCaptureDescriptorDataEXT,
	GetBufferDeviceAddress:                                 ProcGetBufferDeviceAddress,
	GetBufferDeviceAddressEXT:                              ProcGetBufferDeviceAddressEXT,
	GetBufferDeviceAddressKHR:                              ProcGetBufferDeviceAddressKHR,
	GetBufferMemoryRequirements:                            ProcGetBufferMemoryRequirements,
	GetBufferMemoryRequirements2:                           ProcGetBufferMemoryRequirements2,
	GetBufferMemoryRequirements2KHR:                        ProcGetBufferMemoryRequirements2KHR,
	GetBufferOpaqueCaptureAddress:                          ProcGetBufferOpaqueCaptureAddress,
	GetBufferOpaqueCaptureAddressKHR:                       ProcGetBufferOpaqueCaptureAddressKHR,
	GetBufferOpaqueCaptureDescriptorDataEXT:                ProcGetBufferOpaqueCaptureDescriptorDataEXT,
	GetCalibratedTimestampsEXT:                             ProcGetCalibratedTimestampsEXT,
	GetDeferredOperationMaxConcurrencyKHR:                  ProcGetDeferredOperationMaxConcurrencyKHR,
	GetDeferredOperationResultKHR:                          ProcGetDeferredOperationResultKHR,
	GetDescriptorEXT:                                       ProcGetDescriptorEXT,
	GetDescriptorSetHostMappingVALVE:                       ProcGetDescriptorSetHostMappingVALVE,
	GetDescriptorSetLayoutBindingOffsetEXT:                 ProcGetDescriptorSetLayoutBindingOffsetEXT,
	GetDescriptorSetLayoutHostMappingInfoVALVE:             ProcGetDescriptorSetLayoutHostMappingInfoVALVE,
	GetDescriptorSetLayoutSizeEXT:                          ProcGetDescriptorSetLayoutSizeEXT,
	GetDescriptorSetLayoutSupport:                          ProcGetDescriptorSetLayoutSupport,
	GetDescriptorSetLayoutSupportKHR:                       ProcGetDescriptorSetLayoutSupportKHR,
	GetDeviceAccelerationStructureCompatibilityKHR:         ProcGetDeviceAccelerationStructureCompatibilityKHR,
	GetDeviceBufferMemoryRequirements:                      ProcGetDeviceBufferMemoryRequirements,
	GetDeviceBufferMemoryRequirementsKHR:                   ProcGetDeviceBufferMemoryRequirementsKHR,
	GetDeviceFaultInfoEXT:                                  ProcGetDeviceFaultInfoEXT,
	GetDeviceGroupPeerMemoryFeatures:                       ProcGetDeviceGroupPeerMemoryFeatures,
	GetDeviceGroupPeerMemoryFeaturesKHR:                    ProcGetDeviceGroupPeerMemoryFeaturesKHR,
	GetDeviceGroupPresentCapabilitiesKHR:                   ProcGetDeviceGroupPresentCapabilitiesKHR,
	GetDeviceGroupSurfacePresentModes2EXT:                  ProcGetDeviceGroupSurfacePresentModes2EXT,
	GetDeviceGroupSurfacePresentModesKHR:                   ProcGetDeviceGroupSurfacePresentModesKHR,
	GetDeviceImageMemoryRequirements:                       ProcGetDeviceImageMemoryRequirements,
	GetDeviceImageMemoryRequirementsKHR:                    ProcGetDeviceImageMemoryRequirementsKHR,
	GetDeviceImageSparseMemoryRequirements:                 ProcGetDeviceImageSparseMemoryRequirements,
	GetDeviceImageSparseMemoryRequirementsKHR:              ProcGetDeviceImageSparseMemoryRequirementsKHR,
	GetDeviceMemoryCommitment:                              ProcGetDeviceMemoryCommitment,
	GetDeviceMemoryOpaqueCaptureAddress:                    ProcGetDeviceMemoryOpaqueCaptureAddress,
	GetDeviceMemoryOpaqueCaptureAddressKHR:                 ProcGetDeviceMemoryOpaqueCaptureAddressKHR,
	GetDeviceMicromapCompatibilityEXT:                      ProcGetDeviceMicromapCompatibilityEXT,
	GetDeviceProcAddr:                                      ProcGetDeviceProcAddr,
	GetDeviceQueue:                                         ProcGetDeviceQueue,
	GetDeviceQueue2:                                        ProcGetDeviceQueue2,
	GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI:          ProcGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI,
	GetDynamicRenderingTilePropertiesQCOM:                  ProcGetDynamicRenderingTilePropertiesQCOM,
	GetEventStatus:                                         ProcGetEventStatus,
	GetFenceFdKHR:                                          ProcGetFenceFdKHR,
	GetFenceStatus:                                         ProcGetFenceStatus,
	GetFenceWin32HandleKHR:                                 ProcGetFenceWin32HandleKHR,
	GetFramebufferTilePropertiesQCOM:                       ProcGetFramebufferTilePropertiesQCOM,
	GetGeneratedCommandsMemoryRequirementsNV:               ProcGetGeneratedCommandsMemoryRequirementsNV,
	GetImageDrmFormatModifierPropertiesEXT:                 ProcGetImageDrmFormatModifierPropertiesEXT,
	GetImageMemoryRequirements:                             ProcGetImageMemoryRequirements,
	GetImageMemoryRequirements2:                            ProcGetImageMemoryRequirements2,
	GetImageMemoryRequirements2KHR:                         ProcGetImageMemoryRequirements2KHR,
	GetImageOpaqueCaptureDescriptorDataEXT:                 ProcGetImageOpaqueCaptureDescriptorDataEXT,
	GetImageSparseMemoryRequirements:                       ProcGetImageSparseMemoryRequirements,
	GetImageSparseMemoryRequirements2:                      ProcGetImageSparseMemoryRequirements2,
	GetImageSparseMemoryRequirements2KHR:                   ProcGetImageSparseMemoryRequirements2KHR,
	GetImageSubresourceLayout:                              ProcGetImageSubresourceLayout,
	GetImageSubresourceLayout2EXT:                          ProcGetImageSubresourceLayout2EXT,
	GetImageViewAddressNVX:                                 ProcGetImageViewAddressNVX,
	GetImageViewHandleNVX:                                  ProcGetImageViewHandleNVX,
	GetImageViewOpaqueCaptureDescriptorDataEXT:             ProcGetImageViewOpaqueCaptureDescriptorDataEXT,
	GetMemoryFdKHR:                                         ProcGetMemoryFdKHR,
	GetMemoryFdPropertiesKHR:                               ProcGetMemoryFdPropertiesKHR,
	GetMemoryHostPointerPropertiesEXT:                      ProcGetMemoryHostPointerPropertiesEXT,
	GetMemoryRemoteAddressNV:                               ProcGetMemoryRemoteAddressNV,
	GetMemoryWin32HandleKHR:                                ProcGetMemoryWin32HandleKHR,
	GetMemoryWin32HandleNV:                                 ProcGetMemoryWin32HandleNV,
	GetMemoryWin32HandlePropertiesKHR:                      ProcGetMemoryWin32HandlePropertiesKHR,
	GetMicromapBuildSizesEXT:                               ProcGetMicromapBuildSizesEXT,
	GetPastPresentationTimingGOOGLE:                        ProcGetPastPresentationTimingGOOGLE,
	GetPerformanceParameterINTEL:                           ProcGetPerformanceParameterINTEL,
	GetPipelineCacheData:                                   ProcGetPipelineCacheData,
	GetPipelineExecutableInternalRepresentationsKHR:        ProcGetPipelineExecutableInternalRepresentationsKHR,
	GetPipelineExecutablePropertiesKHR:                     ProcGetPipelineExecutablePropertiesKHR,
	GetPipelineExecutableStatisticsKHR:                     ProcGetPipelineExecutableStatisticsKHR,
	GetPipelinePropertiesEXT:                               ProcGetPipelinePropertiesEXT,
	GetPrivateData:                                         ProcGetPrivateData,
	GetPrivateDataEXT:                                      ProcGetPrivateDataEXT,
	GetQueryPoolResults:                                    ProcGetQueryPoolResults,
	GetQueueCheckpointData2NV:                              ProcGetQueueCheckpointData2NV,
	GetQueueCheckpointDataNV:                               ProcGetQueueCheckpointDataNV,
	GetRayTracingCaptureReplayShaderGroupHandlesKHR:        ProcGetRayTracingCaptureReplayShaderGroupHandlesKHR,
	GetRayTracingShaderGroupHandlesKHR:                     ProcGetRayTracingShaderGroupHandlesKHR,
	GetRayTracingShaderGroupHandlesNV:                      ProcGetRayTracingShaderGroupHandlesNV,
	GetRayTracingShaderGroupStackSizeKHR:                   ProcGetRayTracingShaderGroupStackSizeKHR,
	GetRefreshCycleDurationGOOGLE:                          ProcGetRefreshCycleDurationGOOGLE,
	GetRenderAreaGranularity:                               ProcGetRenderAreaGranularity,
	GetSamplerOpaqueCaptureDescriptorDataEXT:               ProcGetSamplerOpaqueCaptureDescriptorDataEXT,
	GetSemaphoreCounterValue:                               ProcGetSemaphoreCounterValue,
	GetSemaphoreCounterValueKHR:                            ProcGetSemaphoreCounterValueKHR,
	GetSemaphoreFdKHR:                                      ProcGetSemaphoreFdKHR,
	GetSemaphoreWin32HandleKHR:                             ProcGetSemaphoreWin32HandleKHR,
	GetShaderBinaryDataEXT:                                 ProcGetShaderBinaryDataEXT,
	GetShaderInfoAMD:                                       ProcGetShaderInfoAMD,
	GetShaderModuleCreateInfoIdentifierEXT:                 ProcGetShaderModuleCreateInfoIdentifierEXT,
	GetShaderModuleIdentifierEXT:                           ProcGetShaderModuleIdentifierEXT,
	GetSwapchainCounterEXT:                                 ProcGetSwapchainCounterEXT,
	GetSwapchainImagesKHR:                                  ProcGetSwapchainImagesKHR,
	GetSwapchainStatusKHR:                                  ProcGetSwapchainStatusKHR,
	GetValidationCacheDataEXT:                              ProcGetValidationCacheDataEXT,
	GetVideoSessionMemoryRequirementsKHR:                   ProcGetVideoSessionMemoryRequirementsKHR,
	ImportFenceFdKHR:                                       ProcImportFenceFdKHR,
	ImportFenceWin32HandleKHR:                              ProcImportFenceWin32HandleKHR,
	ImportSemaphoreFdKHR:                                   ProcImportSemaphoreFdKHR,
	ImportSemaphoreWin32HandleKHR:                          ProcImportSemaphoreWin32HandleKHR,
	InitializePerformanceApiINTEL:                          ProcInitializePerformanceApiINTEL,
	InvalidateMappedMemoryRanges:                           ProcInvalidateMappedMemoryRanges,
	MapMemory:                                              ProcMapMemory,
	MapMemory2KHR:                                          ProcMapMemory2KHR,
	MergePipelineCaches:                                    ProcMergePipelineCaches,
	MergeValidationCachesEXT:                               ProcMergeValidationCachesEXT,
	QueueBeginDebugUtilsLabelEXT:                           ProcQueueBeginDebugUtilsLabelEXT,
	QueueBindSparse:                                        ProcQueueBindSparse,
	QueueEndDebugUtilsLabelEXT:                             ProcQueueEndDebugUtilsLabelEXT,
	QueueInsertDebugUtilsLabelEXT:                          ProcQueueInsertDebugUtilsLabelEXT,
	QueuePresentKHR:                                        ProcQueuePresentKHR,
	QueueSetPerformanceConfigurationINTEL:                  ProcQueueSetPerformanceConfigurationINTEL,
	QueueSubmit:                                            ProcQueueSubmit,
	QueueSubmit2:                                           ProcQueueSubmit2,
	QueueSubmit2KHR:                                        ProcQueueSubmit2KHR,
	QueueWaitIdle:                                          ProcQueueWaitIdle,
	RegisterDeviceEventEXT:                                 ProcRegisterDeviceEventEXT,
	RegisterDisplayEventEXT:                                ProcRegisterDisplayEventEXT,
	ReleaseFullScreenExclusiveModeEXT:                      ProcReleaseFullScreenExclusiveModeEXT,
	ReleasePerformanceConfigurationINTEL:                   ProcReleasePerformanceConfigurationINTEL,
	ReleaseProfilingLockKHR:                                ProcReleaseProfilingLockKHR,
	ReleaseSwapchainImagesEXT:                              ProcReleaseSwapchainImagesEXT,
	ResetCommandBuffer:                                     ProcResetCommandBuffer,
	ResetCommandPool:                                       ProcResetCommandPool,
	ResetDescriptorPool:                                    ProcResetDescriptorPool,
	ResetEvent:                                             ProcResetEvent,
	ResetFences:                                            ProcResetFences,
	ResetQueryPool:                                         ProcResetQueryPool,
	ResetQueryPoolEXT:                                      ProcResetQueryPoolEXT,
	SetDebugUtilsObjectNameEXT:                             ProcSetDebugUtilsObjectNameEXT,
	SetDebugUtilsObjectTagEXT:                              ProcSetDebugUtilsObjectTagEXT,
	SetDeviceMemoryPriorityEXT:                             ProcSetDeviceMemoryPriorityEXT,
	SetEvent:                                               ProcSetEvent,
	SetHdrMetadataEXT:                                      ProcSetHdrMetadataEXT,
	SetLocalDimmingAMD:                                     ProcSetLocalDimmingAMD,
	SetPrivateData:                                         ProcSetPrivateData,
	SetPrivateDataEXT:                                      ProcSetPrivateDataEXT,
	SignalSemaphore:                                        ProcSignalSemaphore,
	SignalSemaphoreKHR:                                     ProcSignalSemaphoreKHR,
	TrimCommandPool:                                        ProcTrimCommandPool,
	TrimCommandPoolKHR:                                     ProcTrimCommandPoolKHR,
	UninitializePerformanceApiINTEL:                        ProcUninitializePerformanceApiINTEL,
	UnmapMemory:                                            ProcUnmapMemory,
	UnmapMemory2KHR:                                        ProcUnmapMemory2KHR,
	UpdateDescriptorSetWithTemplate:                        ProcUpdateDescriptorSetWithTemplate,
	UpdateDescriptorSetWithTemplateKHR:                     ProcUpdateDescriptorSetWithTemplateKHR,
	UpdateDescriptorSets:                                   ProcUpdateDescriptorSets,
	UpdateVideoSessionParametersKHR:                        ProcUpdateVideoSessionParametersKHR,
	WaitForFences:                                          ProcWaitForFences,
	WaitForPresentKHR:                                      ProcWaitForPresentKHR,
	WaitSemaphores:                                         ProcWaitSemaphores,
	WaitSemaphoresKHR:                                      ProcWaitSemaphoresKHR,
	WriteAccelerationStructuresPropertiesKHR:               ProcWriteAccelerationStructuresPropertiesKHR,
	WriteMicromapsPropertiesEXT:                            ProcWriteMicromapsPropertiesEXT,
}

load_proc_addresses_device_vtable :: proc(device: Device, vtable: ^Device_VTable) {
	vtable.AcquireFullScreenExclusiveModeEXT                      = auto_cast GetDeviceProcAddr(device, "vkAcquireFullScreenExclusiveModeEXT")
	vtable.AcquireNextImage2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkAcquireNextImage2KHR")
	vtable.AcquireNextImageKHR                                    = auto_cast GetDeviceProcAddr(device, "vkAcquireNextImageKHR")
	vtable.AcquirePerformanceConfigurationINTEL                   = auto_cast GetDeviceProcAddr(device, "vkAcquirePerformanceConfigurationINTEL")
	vtable.AcquireProfilingLockKHR                                = auto_cast GetDeviceProcAddr(device, "vkAcquireProfilingLockKHR")
	vtable.AllocateCommandBuffers                                 = auto_cast GetDeviceProcAddr(device, "vkAllocateCommandBuffers")
	vtable.AllocateDescriptorSets                                 = auto_cast GetDeviceProcAddr(device, "vkAllocateDescriptorSets")
	vtable.AllocateMemory                                         = auto_cast GetDeviceProcAddr(device, "vkAllocateMemory")
	vtable.BeginCommandBuffer                                     = auto_cast GetDeviceProcAddr(device, "vkBeginCommandBuffer")
	vtable.BindAccelerationStructureMemoryNV                      = auto_cast GetDeviceProcAddr(device, "vkBindAccelerationStructureMemoryNV")
	vtable.BindBufferMemory                                       = auto_cast GetDeviceProcAddr(device, "vkBindBufferMemory")
	vtable.BindBufferMemory2                                      = auto_cast GetDeviceProcAddr(device, "vkBindBufferMemory2")
	vtable.BindBufferMemory2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkBindBufferMemory2KHR")
	vtable.BindImageMemory                                        = auto_cast GetDeviceProcAddr(device, "vkBindImageMemory")
	vtable.BindImageMemory2                                       = auto_cast GetDeviceProcAddr(device, "vkBindImageMemory2")
	vtable.BindImageMemory2KHR                                    = auto_cast GetDeviceProcAddr(device, "vkBindImageMemory2KHR")
	vtable.BindOpticalFlowSessionImageNV                          = auto_cast GetDeviceProcAddr(device, "vkBindOpticalFlowSessionImageNV")
	vtable.BindVideoSessionMemoryKHR                              = auto_cast GetDeviceProcAddr(device, "vkBindVideoSessionMemoryKHR")
	vtable.BuildAccelerationStructuresKHR                         = auto_cast GetDeviceProcAddr(device, "vkBuildAccelerationStructuresKHR")
	vtable.BuildMicromapsEXT                                      = auto_cast GetDeviceProcAddr(device, "vkBuildMicromapsEXT")
	vtable.CmdBeginConditionalRenderingEXT                        = auto_cast GetDeviceProcAddr(device, "vkCmdBeginConditionalRenderingEXT")
	vtable.CmdBeginDebugUtilsLabelEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdBeginDebugUtilsLabelEXT")
	vtable.CmdBeginQuery                                          = auto_cast GetDeviceProcAddr(device, "vkCmdBeginQuery")
	vtable.CmdBeginQueryIndexedEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdBeginQueryIndexedEXT")
	vtable.CmdBeginRenderPass                                     = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderPass")
	vtable.CmdBeginRenderPass2                                    = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderPass2")
	vtable.CmdBeginRenderPass2KHR                                 = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderPass2KHR")
	vtable.CmdBeginRendering                                      = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRendering")
	vtable.CmdBeginRenderingKHR                                   = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderingKHR")
	vtable.CmdBeginTransformFeedbackEXT                           = auto_cast GetDeviceProcAddr(device, "vkCmdBeginTransformFeedbackEXT")
	vtable.CmdBeginVideoCodingKHR                                 = auto_cast GetDeviceProcAddr(device, "vkCmdBeginVideoCodingKHR")
	vtable.CmdBindDescriptorBufferEmbeddedSamplersEXT             = auto_cast GetDeviceProcAddr(device, "vkCmdBindDescriptorBufferEmbeddedSamplersEXT")
	vtable.CmdBindDescriptorBuffersEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdBindDescriptorBuffersEXT")
	vtable.CmdBindDescriptorSets                                  = auto_cast GetDeviceProcAddr(device, "vkCmdBindDescriptorSets")
	vtable.CmdBindIndexBuffer                                     = auto_cast GetDeviceProcAddr(device, "vkCmdBindIndexBuffer")
	vtable.CmdBindInvocationMaskHUAWEI                            = auto_cast GetDeviceProcAddr(device, "vkCmdBindInvocationMaskHUAWEI")
	vtable.CmdBindPipeline                                        = auto_cast GetDeviceProcAddr(device, "vkCmdBindPipeline")
	vtable.CmdBindPipelineShaderGroupNV                           = auto_cast GetDeviceProcAddr(device, "vkCmdBindPipelineShaderGroupNV")
	vtable.CmdBindShadersEXT                                      = auto_cast GetDeviceProcAddr(device, "vkCmdBindShadersEXT")
	vtable.CmdBindShadingRateImageNV                              = auto_cast GetDeviceProcAddr(device, "vkCmdBindShadingRateImageNV")
	vtable.CmdBindTransformFeedbackBuffersEXT                     = auto_cast GetDeviceProcAddr(device, "vkCmdBindTransformFeedbackBuffersEXT")
	vtable.CmdBindVertexBuffers                                   = auto_cast GetDeviceProcAddr(device, "vkCmdBindVertexBuffers")
	vtable.CmdBindVertexBuffers2                                  = auto_cast GetDeviceProcAddr(device, "vkCmdBindVertexBuffers2")
	vtable.CmdBindVertexBuffers2EXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdBindVertexBuffers2EXT")
	vtable.CmdBlitImage                                           = auto_cast GetDeviceProcAddr(device, "vkCmdBlitImage")
	vtable.CmdBlitImage2                                          = auto_cast GetDeviceProcAddr(device, "vkCmdBlitImage2")
	vtable.CmdBlitImage2KHR                                       = auto_cast GetDeviceProcAddr(device, "vkCmdBlitImage2KHR")
	vtable.CmdBuildAccelerationStructureNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdBuildAccelerationStructureNV")
	vtable.CmdBuildAccelerationStructuresIndirectKHR              = auto_cast GetDeviceProcAddr(device, "vkCmdBuildAccelerationStructuresIndirectKHR")
	vtable.CmdBuildAccelerationStructuresKHR                      = auto_cast GetDeviceProcAddr(device, "vkCmdBuildAccelerationStructuresKHR")
	vtable.CmdBuildMicromapsEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdBuildMicromapsEXT")
	vtable.CmdClearAttachments                                    = auto_cast GetDeviceProcAddr(device, "vkCmdClearAttachments")
	vtable.CmdClearColorImage                                     = auto_cast GetDeviceProcAddr(device, "vkCmdClearColorImage")
	vtable.CmdClearDepthStencilImage                              = auto_cast GetDeviceProcAddr(device, "vkCmdClearDepthStencilImage")
	vtable.CmdControlVideoCodingKHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdControlVideoCodingKHR")
	vtable.CmdCopyAccelerationStructureKHR                        = auto_cast GetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureKHR")
	vtable.CmdCopyAccelerationStructureNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureNV")
	vtable.CmdCopyAccelerationStructureToMemoryKHR                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureToMemoryKHR")
	vtable.CmdCopyBuffer                                          = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBuffer")
	vtable.CmdCopyBuffer2                                         = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBuffer2")
	vtable.CmdCopyBuffer2KHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBuffer2KHR")
	vtable.CmdCopyBufferToImage                                   = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBufferToImage")
	vtable.CmdCopyBufferToImage2                                  = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBufferToImage2")
	vtable.CmdCopyBufferToImage2KHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBufferToImage2KHR")
	vtable.CmdCopyImage                                           = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImage")
	vtable.CmdCopyImage2                                          = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImage2")
	vtable.CmdCopyImage2KHR                                       = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImage2KHR")
	vtable.CmdCopyImageToBuffer                                   = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImageToBuffer")
	vtable.CmdCopyImageToBuffer2                                  = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImageToBuffer2")
	vtable.CmdCopyImageToBuffer2KHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImageToBuffer2KHR")
	vtable.CmdCopyMemoryIndirectNV                                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryIndirectNV")
	vtable.CmdCopyMemoryToAccelerationStructureKHR                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryToAccelerationStructureKHR")
	vtable.CmdCopyMemoryToImageIndirectNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryToImageIndirectNV")
	vtable.CmdCopyMemoryToMicromapEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryToMicromapEXT")
	vtable.CmdCopyMicromapEXT                                     = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMicromapEXT")
	vtable.CmdCopyMicromapToMemoryEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMicromapToMemoryEXT")
	vtable.CmdCopyQueryPoolResults                                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyQueryPoolResults")
	vtable.CmdCuLaunchKernelNVX                                   = auto_cast GetDeviceProcAddr(device, "vkCmdCuLaunchKernelNVX")
	vtable.CmdDebugMarkerBeginEXT                                 = auto_cast GetDeviceProcAddr(device, "vkCmdDebugMarkerBeginEXT")
	vtable.CmdDebugMarkerEndEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdDebugMarkerEndEXT")
	vtable.CmdDebugMarkerInsertEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdDebugMarkerInsertEXT")
	vtable.CmdDecodeVideoKHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdDecodeVideoKHR")
	vtable.CmdDecompressMemoryIndirectCountNV                     = auto_cast GetDeviceProcAddr(device, "vkCmdDecompressMemoryIndirectCountNV")
	vtable.CmdDecompressMemoryNV                                  = auto_cast GetDeviceProcAddr(device, "vkCmdDecompressMemoryNV")
	vtable.CmdDispatch                                            = auto_cast GetDeviceProcAddr(device, "vkCmdDispatch")
	vtable.CmdDispatchBase                                        = auto_cast GetDeviceProcAddr(device, "vkCmdDispatchBase")
	vtable.CmdDispatchBaseKHR                                     = auto_cast GetDeviceProcAddr(device, "vkCmdDispatchBaseKHR")
	vtable.CmdDispatchIndirect                                    = auto_cast GetDeviceProcAddr(device, "vkCmdDispatchIndirect")
	vtable.CmdDraw                                                = auto_cast GetDeviceProcAddr(device, "vkCmdDraw")
	vtable.CmdDrawClusterHUAWEI                                   = auto_cast GetDeviceProcAddr(device, "vkCmdDrawClusterHUAWEI")
	vtable.CmdDrawClusterIndirectHUAWEI                           = auto_cast GetDeviceProcAddr(device, "vkCmdDrawClusterIndirectHUAWEI")
	vtable.CmdDrawIndexed                                         = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexed")
	vtable.CmdDrawIndexedIndirect                                 = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirect")
	vtable.CmdDrawIndexedIndirectCount                            = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCount")
	vtable.CmdDrawIndexedIndirectCountAMD                         = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCountAMD")
	vtable.CmdDrawIndexedIndirectCountKHR                         = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCountKHR")
	vtable.CmdDrawIndirect                                        = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirect")
	vtable.CmdDrawIndirectByteCountEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectByteCountEXT")
	vtable.CmdDrawIndirectCount                                   = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectCount")
	vtable.CmdDrawIndirectCountAMD                                = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectCountAMD")
	vtable.CmdDrawIndirectCountKHR                                = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectCountKHR")
	vtable.CmdDrawMeshTasksEXT                                    = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksEXT")
	vtable.CmdDrawMeshTasksIndirectCountEXT                       = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectCountEXT")
	vtable.CmdDrawMeshTasksIndirectCountNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectCountNV")
	vtable.CmdDrawMeshTasksIndirectEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectEXT")
	vtable.CmdDrawMeshTasksIndirectNV                             = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectNV")
	vtable.CmdDrawMeshTasksNV                                     = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksNV")
	vtable.CmdDrawMultiEXT                                        = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMultiEXT")
	vtable.CmdDrawMultiIndexedEXT                                 = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMultiIndexedEXT")
	vtable.CmdEndConditionalRenderingEXT                          = auto_cast GetDeviceProcAddr(device, "vkCmdEndConditionalRenderingEXT")
	vtable.CmdEndDebugUtilsLabelEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdEndDebugUtilsLabelEXT")
	vtable.CmdEndQuery                                            = auto_cast GetDeviceProcAddr(device, "vkCmdEndQuery")
	vtable.CmdEndQueryIndexedEXT                                  = auto_cast GetDeviceProcAddr(device, "vkCmdEndQueryIndexedEXT")
	vtable.CmdEndRenderPass                                       = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderPass")
	vtable.CmdEndRenderPass2                                      = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderPass2")
	vtable.CmdEndRenderPass2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderPass2KHR")
	vtable.CmdEndRendering                                        = auto_cast GetDeviceProcAddr(device, "vkCmdEndRendering")
	vtable.CmdEndRenderingKHR                                     = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderingKHR")
	vtable.CmdEndTransformFeedbackEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdEndTransformFeedbackEXT")
	vtable.CmdEndVideoCodingKHR                                   = auto_cast GetDeviceProcAddr(device, "vkCmdEndVideoCodingKHR")
	vtable.CmdExecuteCommands                                     = auto_cast GetDeviceProcAddr(device, "vkCmdExecuteCommands")
	vtable.CmdExecuteGeneratedCommandsNV                          = auto_cast GetDeviceProcAddr(device, "vkCmdExecuteGeneratedCommandsNV")
	vtable.CmdFillBuffer                                          = auto_cast GetDeviceProcAddr(device, "vkCmdFillBuffer")
	vtable.CmdInsertDebugUtilsLabelEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdInsertDebugUtilsLabelEXT")
	vtable.CmdNextSubpass                                         = auto_cast GetDeviceProcAddr(device, "vkCmdNextSubpass")
	vtable.CmdNextSubpass2                                        = auto_cast GetDeviceProcAddr(device, "vkCmdNextSubpass2")
	vtable.CmdNextSubpass2KHR                                     = auto_cast GetDeviceProcAddr(device, "vkCmdNextSubpass2KHR")
	vtable.CmdOpticalFlowExecuteNV                                = auto_cast GetDeviceProcAddr(device, "vkCmdOpticalFlowExecuteNV")
	vtable.CmdPipelineBarrier                                     = auto_cast GetDeviceProcAddr(device, "vkCmdPipelineBarrier")
	vtable.CmdPipelineBarrier2                                    = auto_cast GetDeviceProcAddr(device, "vkCmdPipelineBarrier2")
	vtable.CmdPipelineBarrier2KHR                                 = auto_cast GetDeviceProcAddr(device, "vkCmdPipelineBarrier2KHR")
	vtable.CmdPreprocessGeneratedCommandsNV                       = auto_cast GetDeviceProcAddr(device, "vkCmdPreprocessGeneratedCommandsNV")
	vtable.CmdPushConstants                                       = auto_cast GetDeviceProcAddr(device, "vkCmdPushConstants")
	vtable.CmdPushDescriptorSetKHR                                = auto_cast GetDeviceProcAddr(device, "vkCmdPushDescriptorSetKHR")
	vtable.CmdPushDescriptorSetWithTemplateKHR                    = auto_cast GetDeviceProcAddr(device, "vkCmdPushDescriptorSetWithTemplateKHR")
	vtable.CmdResetEvent                                          = auto_cast GetDeviceProcAddr(device, "vkCmdResetEvent")
	vtable.CmdResetEvent2                                         = auto_cast GetDeviceProcAddr(device, "vkCmdResetEvent2")
	vtable.CmdResetEvent2KHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdResetEvent2KHR")
	vtable.CmdResetQueryPool                                      = auto_cast GetDeviceProcAddr(device, "vkCmdResetQueryPool")
	vtable.CmdResolveImage                                        = auto_cast GetDeviceProcAddr(device, "vkCmdResolveImage")
	vtable.CmdResolveImage2                                       = auto_cast GetDeviceProcAddr(device, "vkCmdResolveImage2")
	vtable.CmdResolveImage2KHR                                    = auto_cast GetDeviceProcAddr(device, "vkCmdResolveImage2KHR")
	vtable.CmdSetAlphaToCoverageEnableEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetAlphaToCoverageEnableEXT")
	vtable.CmdSetAlphaToOneEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetAlphaToOneEnableEXT")
	vtable.CmdSetAttachmentFeedbackLoopEnableEXT                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetAttachmentFeedbackLoopEnableEXT")
	vtable.CmdSetBlendConstants                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetBlendConstants")
	vtable.CmdSetCheckpointNV                                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetCheckpointNV")
	vtable.CmdSetCoarseSampleOrderNV                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoarseSampleOrderNV")
	vtable.CmdSetColorBlendAdvancedEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorBlendAdvancedEXT")
	vtable.CmdSetColorBlendEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorBlendEnableEXT")
	vtable.CmdSetColorBlendEquationEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorBlendEquationEXT")
	vtable.CmdSetColorWriteMaskEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorWriteMaskEXT")
	vtable.CmdSetConservativeRasterizationModeEXT                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetConservativeRasterizationModeEXT")
	vtable.CmdSetCoverageModulationModeNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageModulationModeNV")
	vtable.CmdSetCoverageModulationTableEnableNV                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageModulationTableEnableNV")
	vtable.CmdSetCoverageModulationTableNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageModulationTableNV")
	vtable.CmdSetCoverageReductionModeNV                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageReductionModeNV")
	vtable.CmdSetCoverageToColorEnableNV                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageToColorEnableNV")
	vtable.CmdSetCoverageToColorLocationNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageToColorLocationNV")
	vtable.CmdSetCullMode                                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetCullMode")
	vtable.CmdSetCullModeEXT                                      = auto_cast GetDeviceProcAddr(device, "vkCmdSetCullModeEXT")
	vtable.CmdSetDepthBias                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBias")
	vtable.CmdSetDepthBiasEnable                                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBiasEnable")
	vtable.CmdSetDepthBiasEnableEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBiasEnableEXT")
	vtable.CmdSetDepthBounds                                      = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBounds")
	vtable.CmdSetDepthBoundsTestEnable                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBoundsTestEnable")
	vtable.CmdSetDepthBoundsTestEnableEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBoundsTestEnableEXT")
	vtable.CmdSetDepthClampEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthClampEnableEXT")
	vtable.CmdSetDepthClipEnableEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthClipEnableEXT")
	vtable.CmdSetDepthClipNegativeOneToOneEXT                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthClipNegativeOneToOneEXT")
	vtable.CmdSetDepthCompareOp                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthCompareOp")
	vtable.CmdSetDepthCompareOpEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthCompareOpEXT")
	vtable.CmdSetDepthTestEnable                                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthTestEnable")
	vtable.CmdSetDepthTestEnableEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthTestEnableEXT")
	vtable.CmdSetDepthWriteEnable                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthWriteEnable")
	vtable.CmdSetDepthWriteEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthWriteEnableEXT")
	vtable.CmdSetDescriptorBufferOffsetsEXT                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetDescriptorBufferOffsetsEXT")
	vtable.CmdSetDeviceMask                                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetDeviceMask")
	vtable.CmdSetDeviceMaskKHR                                    = auto_cast GetDeviceProcAddr(device, "vkCmdSetDeviceMaskKHR")
	vtable.CmdSetDiscardRectangleEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetDiscardRectangleEXT")
	vtable.CmdSetDiscardRectangleEnableEXT                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetDiscardRectangleEnableEXT")
	vtable.CmdSetDiscardRectangleModeEXT                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetDiscardRectangleModeEXT")
	vtable.CmdSetEvent                                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetEvent")
	vtable.CmdSetEvent2                                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetEvent2")
	vtable.CmdSetEvent2KHR                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetEvent2KHR")
	vtable.CmdSetExclusiveScissorEnableNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetExclusiveScissorEnableNV")
	vtable.CmdSetExclusiveScissorNV                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetExclusiveScissorNV")
	vtable.CmdSetExtraPrimitiveOverestimationSizeEXT              = auto_cast GetDeviceProcAddr(device, "vkCmdSetExtraPrimitiveOverestimationSizeEXT")
	vtable.CmdSetFragmentShadingRateEnumNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetFragmentShadingRateEnumNV")
	vtable.CmdSetFragmentShadingRateKHR                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetFragmentShadingRateKHR")
	vtable.CmdSetFrontFace                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetFrontFace")
	vtable.CmdSetFrontFaceEXT                                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetFrontFaceEXT")
	vtable.CmdSetLineRasterizationModeEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineRasterizationModeEXT")
	vtable.CmdSetLineStippleEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineStippleEXT")
	vtable.CmdSetLineStippleEnableEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineStippleEnableEXT")
	vtable.CmdSetLineWidth                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineWidth")
	vtable.CmdSetLogicOpEXT                                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetLogicOpEXT")
	vtable.CmdSetLogicOpEnableEXT                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetLogicOpEnableEXT")
	vtable.CmdSetPatchControlPointsEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetPatchControlPointsEXT")
	vtable.CmdSetPerformanceMarkerINTEL                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetPerformanceMarkerINTEL")
	vtable.CmdSetPerformanceOverrideINTEL                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetPerformanceOverrideINTEL")
	vtable.CmdSetPerformanceStreamMarkerINTEL                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetPerformanceStreamMarkerINTEL")
	vtable.CmdSetPolygonModeEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetPolygonModeEXT")
	vtable.CmdSetPrimitiveRestartEnable                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveRestartEnable")
	vtable.CmdSetPrimitiveRestartEnableEXT                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveRestartEnableEXT")
	vtable.CmdSetPrimitiveTopology                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveTopology")
	vtable.CmdSetPrimitiveTopologyEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveTopologyEXT")
	vtable.CmdSetProvokingVertexModeEXT                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetProvokingVertexModeEXT")
	vtable.CmdSetRasterizationSamplesEXT                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizationSamplesEXT")
	vtable.CmdSetRasterizationStreamEXT                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizationStreamEXT")
	vtable.CmdSetRasterizerDiscardEnable                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizerDiscardEnable")
	vtable.CmdSetRasterizerDiscardEnableEXT                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizerDiscardEnableEXT")
	vtable.CmdSetRayTracingPipelineStackSizeKHR                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetRayTracingPipelineStackSizeKHR")
	vtable.CmdSetRepresentativeFragmentTestEnableNV               = auto_cast GetDeviceProcAddr(device, "vkCmdSetRepresentativeFragmentTestEnableNV")
	vtable.CmdSetSampleLocationsEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetSampleLocationsEXT")
	vtable.CmdSetSampleLocationsEnableEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetSampleLocationsEnableEXT")
	vtable.CmdSetSampleMaskEXT                                    = auto_cast GetDeviceProcAddr(device, "vkCmdSetSampleMaskEXT")
	vtable.CmdSetScissor                                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetScissor")
	vtable.CmdSetScissorWithCount                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetScissorWithCount")
	vtable.CmdSetScissorWithCountEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetScissorWithCountEXT")
	vtable.CmdSetShadingRateImageEnableNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetShadingRateImageEnableNV")
	vtable.CmdSetStencilCompareMask                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilCompareMask")
	vtable.CmdSetStencilOp                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilOp")
	vtable.CmdSetStencilOpEXT                                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilOpEXT")
	vtable.CmdSetStencilReference                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilReference")
	vtable.CmdSetStencilTestEnable                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilTestEnable")
	vtable.CmdSetStencilTestEnableEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilTestEnableEXT")
	vtable.CmdSetStencilWriteMask                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilWriteMask")
	vtable.CmdSetTessellationDomainOriginEXT                      = auto_cast GetDeviceProcAddr(device, "vkCmdSetTessellationDomainOriginEXT")
	vtable.CmdSetVertexInputEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetVertexInputEXT")
	vtable.CmdSetViewport                                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewport")
	vtable.CmdSetViewportShadingRatePaletteNV                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportShadingRatePaletteNV")
	vtable.CmdSetViewportSwizzleNV                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportSwizzleNV")
	vtable.CmdSetViewportWScalingEnableNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWScalingEnableNV")
	vtable.CmdSetViewportWScalingNV                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWScalingNV")
	vtable.CmdSetViewportWithCount                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWithCount")
	vtable.CmdSetViewportWithCountEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWithCountEXT")
	vtable.CmdSubpassShadingHUAWEI                                = auto_cast GetDeviceProcAddr(device, "vkCmdSubpassShadingHUAWEI")
	vtable.CmdTraceRaysIndirect2KHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysIndirect2KHR")
	vtable.CmdTraceRaysIndirectKHR                                = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysIndirectKHR")
	vtable.CmdTraceRaysKHR                                        = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysKHR")
	vtable.CmdTraceRaysNV                                         = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysNV")
	vtable.CmdUpdateBuffer                                        = auto_cast GetDeviceProcAddr(device, "vkCmdUpdateBuffer")
	vtable.CmdWaitEvents                                          = auto_cast GetDeviceProcAddr(device, "vkCmdWaitEvents")
	vtable.CmdWaitEvents2                                         = auto_cast GetDeviceProcAddr(device, "vkCmdWaitEvents2")
	vtable.CmdWaitEvents2KHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdWaitEvents2KHR")
	vtable.CmdWriteAccelerationStructuresPropertiesKHR            = auto_cast GetDeviceProcAddr(device, "vkCmdWriteAccelerationStructuresPropertiesKHR")
	vtable.CmdWriteAccelerationStructuresPropertiesNV             = auto_cast GetDeviceProcAddr(device, "vkCmdWriteAccelerationStructuresPropertiesNV")
	vtable.CmdWriteBufferMarker2AMD                               = auto_cast GetDeviceProcAddr(device, "vkCmdWriteBufferMarker2AMD")
	vtable.CmdWriteBufferMarkerAMD                                = auto_cast GetDeviceProcAddr(device, "vkCmdWriteBufferMarkerAMD")
	vtable.CmdWriteMicromapsPropertiesEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdWriteMicromapsPropertiesEXT")
	vtable.CmdWriteTimestamp                                      = auto_cast GetDeviceProcAddr(device, "vkCmdWriteTimestamp")
	vtable.CmdWriteTimestamp2                                     = auto_cast GetDeviceProcAddr(device, "vkCmdWriteTimestamp2")
	vtable.CmdWriteTimestamp2KHR                                  = auto_cast GetDeviceProcAddr(device, "vkCmdWriteTimestamp2KHR")
	vtable.CompileDeferredNV                                      = auto_cast GetDeviceProcAddr(device, "vkCompileDeferredNV")
	vtable.CopyAccelerationStructureKHR                           = auto_cast GetDeviceProcAddr(device, "vkCopyAccelerationStructureKHR")
	vtable.CopyAccelerationStructureToMemoryKHR                   = auto_cast GetDeviceProcAddr(device, "vkCopyAccelerationStructureToMemoryKHR")
	vtable.CopyMemoryToAccelerationStructureKHR                   = auto_cast GetDeviceProcAddr(device, "vkCopyMemoryToAccelerationStructureKHR")
	vtable.CopyMemoryToMicromapEXT                                = auto_cast GetDeviceProcAddr(device, "vkCopyMemoryToMicromapEXT")
	vtable.CopyMicromapEXT                                        = auto_cast GetDeviceProcAddr(device, "vkCopyMicromapEXT")
	vtable.CopyMicromapToMemoryEXT                                = auto_cast GetDeviceProcAddr(device, "vkCopyMicromapToMemoryEXT")
	vtable.CreateAccelerationStructureKHR                         = auto_cast GetDeviceProcAddr(device, "vkCreateAccelerationStructureKHR")
	vtable.CreateAccelerationStructureNV                          = auto_cast GetDeviceProcAddr(device, "vkCreateAccelerationStructureNV")
	vtable.CreateBuffer                                           = auto_cast GetDeviceProcAddr(device, "vkCreateBuffer")
	vtable.CreateBufferView                                       = auto_cast GetDeviceProcAddr(device, "vkCreateBufferView")
	vtable.CreateCommandPool                                      = auto_cast GetDeviceProcAddr(device, "vkCreateCommandPool")
	vtable.CreateComputePipelines                                 = auto_cast GetDeviceProcAddr(device, "vkCreateComputePipelines")
	vtable.CreateCuFunctionNVX                                    = auto_cast GetDeviceProcAddr(device, "vkCreateCuFunctionNVX")
	vtable.CreateCuModuleNVX                                      = auto_cast GetDeviceProcAddr(device, "vkCreateCuModuleNVX")
	vtable.CreateDeferredOperationKHR                             = auto_cast GetDeviceProcAddr(device, "vkCreateDeferredOperationKHR")
	vtable.CreateDescriptorPool                                   = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorPool")
	vtable.CreateDescriptorSetLayout                              = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorSetLayout")
	vtable.CreateDescriptorUpdateTemplate                         = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorUpdateTemplate")
	vtable.CreateDescriptorUpdateTemplateKHR                      = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorUpdateTemplateKHR")
	vtable.CreateEvent                                            = auto_cast GetDeviceProcAddr(device, "vkCreateEvent")
	vtable.CreateFence                                            = auto_cast GetDeviceProcAddr(device, "vkCreateFence")
	vtable.CreateFramebuffer                                      = auto_cast GetDeviceProcAddr(device, "vkCreateFramebuffer")
	vtable.CreateGraphicsPipelines                                = auto_cast GetDeviceProcAddr(device, "vkCreateGraphicsPipelines")
	vtable.CreateImage                                            = auto_cast GetDeviceProcAddr(device, "vkCreateImage")
	vtable.CreateImageView                                        = auto_cast GetDeviceProcAddr(device, "vkCreateImageView")
	vtable.CreateIndirectCommandsLayoutNV                         = auto_cast GetDeviceProcAddr(device, "vkCreateIndirectCommandsLayoutNV")
	vtable.CreateMicromapEXT                                      = auto_cast GetDeviceProcAddr(device, "vkCreateMicromapEXT")
	vtable.CreateOpticalFlowSessionNV                             = auto_cast GetDeviceProcAddr(device, "vkCreateOpticalFlowSessionNV")
	vtable.CreatePipelineCache                                    = auto_cast GetDeviceProcAddr(device, "vkCreatePipelineCache")
	vtable.CreatePipelineLayout                                   = auto_cast GetDeviceProcAddr(device, "vkCreatePipelineLayout")
	vtable.CreatePrivateDataSlot                                  = auto_cast GetDeviceProcAddr(device, "vkCreatePrivateDataSlot")
	vtable.CreatePrivateDataSlotEXT                               = auto_cast GetDeviceProcAddr(device, "vkCreatePrivateDataSlotEXT")
	vtable.CreateQueryPool                                        = auto_cast GetDeviceProcAddr(device, "vkCreateQueryPool")
	vtable.CreateRayTracingPipelinesKHR                           = auto_cast GetDeviceProcAddr(device, "vkCreateRayTracingPipelinesKHR")
	vtable.CreateRayTracingPipelinesNV                            = auto_cast GetDeviceProcAddr(device, "vkCreateRayTracingPipelinesNV")
	vtable.CreateRenderPass                                       = auto_cast GetDeviceProcAddr(device, "vkCreateRenderPass")
	vtable.CreateRenderPass2                                      = auto_cast GetDeviceProcAddr(device, "vkCreateRenderPass2")
	vtable.CreateRenderPass2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkCreateRenderPass2KHR")
	vtable.CreateSampler                                          = auto_cast GetDeviceProcAddr(device, "vkCreateSampler")
	vtable.CreateSamplerYcbcrConversion                           = auto_cast GetDeviceProcAddr(device, "vkCreateSamplerYcbcrConversion")
	vtable.CreateSamplerYcbcrConversionKHR                        = auto_cast GetDeviceProcAddr(device, "vkCreateSamplerYcbcrConversionKHR")
	vtable.CreateSemaphore                                        = auto_cast GetDeviceProcAddr(device, "vkCreateSemaphore")
	vtable.CreateShaderModule                                     = auto_cast GetDeviceProcAddr(device, "vkCreateShaderModule")
	vtable.CreateShadersEXT                                       = auto_cast GetDeviceProcAddr(device, "vkCreateShadersEXT")
	vtable.CreateSharedSwapchainsKHR                              = auto_cast GetDeviceProcAddr(device, "vkCreateSharedSwapchainsKHR")
	vtable.CreateSwapchainKHR                                     = auto_cast GetDeviceProcAddr(device, "vkCreateSwapchainKHR")
	vtable.CreateValidationCacheEXT                               = auto_cast GetDeviceProcAddr(device, "vkCreateValidationCacheEXT")
	vtable.CreateVideoSessionKHR                                  = auto_cast GetDeviceProcAddr(device, "vkCreateVideoSessionKHR")
	vtable.CreateVideoSessionParametersKHR                        = auto_cast GetDeviceProcAddr(device, "vkCreateVideoSessionParametersKHR")
	vtable.DebugMarkerSetObjectNameEXT                            = auto_cast GetDeviceProcAddr(device, "vkDebugMarkerSetObjectNameEXT")
	vtable.DebugMarkerSetObjectTagEXT                             = auto_cast GetDeviceProcAddr(device, "vkDebugMarkerSetObjectTagEXT")
	vtable.DeferredOperationJoinKHR                               = auto_cast GetDeviceProcAddr(device, "vkDeferredOperationJoinKHR")
	vtable.DestroyAccelerationStructureKHR                        = auto_cast GetDeviceProcAddr(device, "vkDestroyAccelerationStructureKHR")
	vtable.DestroyAccelerationStructureNV                         = auto_cast GetDeviceProcAddr(device, "vkDestroyAccelerationStructureNV")
	vtable.DestroyBuffer                                          = auto_cast GetDeviceProcAddr(device, "vkDestroyBuffer")
	vtable.DestroyBufferView                                      = auto_cast GetDeviceProcAddr(device, "vkDestroyBufferView")
	vtable.DestroyCommandPool                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyCommandPool")
	vtable.DestroyCuFunctionNVX                                   = auto_cast GetDeviceProcAddr(device, "vkDestroyCuFunctionNVX")
	vtable.DestroyCuModuleNVX                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyCuModuleNVX")
	vtable.DestroyDeferredOperationKHR                            = auto_cast GetDeviceProcAddr(device, "vkDestroyDeferredOperationKHR")
	vtable.DestroyDescriptorPool                                  = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorPool")
	vtable.DestroyDescriptorSetLayout                             = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorSetLayout")
	vtable.DestroyDescriptorUpdateTemplate                        = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorUpdateTemplate")
	vtable.DestroyDescriptorUpdateTemplateKHR                     = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorUpdateTemplateKHR")
	vtable.DestroyDevice                                          = auto_cast GetDeviceProcAddr(device, "vkDestroyDevice")
	vtable.DestroyEvent                                           = auto_cast GetDeviceProcAddr(device, "vkDestroyEvent")
	vtable.DestroyFence                                           = auto_cast GetDeviceProcAddr(device, "vkDestroyFence")
	vtable.DestroyFramebuffer                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyFramebuffer")
	vtable.DestroyImage                                           = auto_cast GetDeviceProcAddr(device, "vkDestroyImage")
	vtable.DestroyImageView                                       = auto_cast GetDeviceProcAddr(device, "vkDestroyImageView")
	vtable.DestroyIndirectCommandsLayoutNV                        = auto_cast GetDeviceProcAddr(device, "vkDestroyIndirectCommandsLayoutNV")
	vtable.DestroyMicromapEXT                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyMicromapEXT")
	vtable.DestroyOpticalFlowSessionNV                            = auto_cast GetDeviceProcAddr(device, "vkDestroyOpticalFlowSessionNV")
	vtable.DestroyPipeline                                        = auto_cast GetDeviceProcAddr(device, "vkDestroyPipeline")
	vtable.DestroyPipelineCache                                   = auto_cast GetDeviceProcAddr(device, "vkDestroyPipelineCache")
	vtable.DestroyPipelineLayout                                  = auto_cast GetDeviceProcAddr(device, "vkDestroyPipelineLayout")
	vtable.DestroyPrivateDataSlot                                 = auto_cast GetDeviceProcAddr(device, "vkDestroyPrivateDataSlot")
	vtable.DestroyPrivateDataSlotEXT                              = auto_cast GetDeviceProcAddr(device, "vkDestroyPrivateDataSlotEXT")
	vtable.DestroyQueryPool                                       = auto_cast GetDeviceProcAddr(device, "vkDestroyQueryPool")
	vtable.DestroyRenderPass                                      = auto_cast GetDeviceProcAddr(device, "vkDestroyRenderPass")
	vtable.DestroySampler                                         = auto_cast GetDeviceProcAddr(device, "vkDestroySampler")
	vtable.DestroySamplerYcbcrConversion                          = auto_cast GetDeviceProcAddr(device, "vkDestroySamplerYcbcrConversion")
	vtable.DestroySamplerYcbcrConversionKHR                       = auto_cast GetDeviceProcAddr(device, "vkDestroySamplerYcbcrConversionKHR")
	vtable.DestroySemaphore                                       = auto_cast GetDeviceProcAddr(device, "vkDestroySemaphore")
	vtable.DestroyShaderEXT                                       = auto_cast GetDeviceProcAddr(device, "vkDestroyShaderEXT")
	vtable.DestroyShaderModule                                    = auto_cast GetDeviceProcAddr(device, "vkDestroyShaderModule")
	vtable.DestroySwapchainKHR                                    = auto_cast GetDeviceProcAddr(device, "vkDestroySwapchainKHR")
	vtable.DestroyValidationCacheEXT                              = auto_cast GetDeviceProcAddr(device, "vkDestroyValidationCacheEXT")
	vtable.DestroyVideoSessionKHR                                 = auto_cast GetDeviceProcAddr(device, "vkDestroyVideoSessionKHR")
	vtable.DestroyVideoSessionParametersKHR                       = auto_cast GetDeviceProcAddr(device, "vkDestroyVideoSessionParametersKHR")
	vtable.DeviceWaitIdle                                         = auto_cast GetDeviceProcAddr(device, "vkDeviceWaitIdle")
	vtable.DisplayPowerControlEXT                                 = auto_cast GetDeviceProcAddr(device, "vkDisplayPowerControlEXT")
	vtable.EndCommandBuffer                                       = auto_cast GetDeviceProcAddr(device, "vkEndCommandBuffer")
	vtable.ExportMetalObjectsEXT                                  = auto_cast GetDeviceProcAddr(device, "vkExportMetalObjectsEXT")
	vtable.FlushMappedMemoryRanges                                = auto_cast GetDeviceProcAddr(device, "vkFlushMappedMemoryRanges")
	vtable.FreeCommandBuffers                                     = auto_cast GetDeviceProcAddr(device, "vkFreeCommandBuffers")
	vtable.FreeDescriptorSets                                     = auto_cast GetDeviceProcAddr(device, "vkFreeDescriptorSets")
	vtable.FreeMemory                                             = auto_cast GetDeviceProcAddr(device, "vkFreeMemory")
	vtable.GetAccelerationStructureBuildSizesKHR                  = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureBuildSizesKHR")
	vtable.GetAccelerationStructureDeviceAddressKHR               = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureDeviceAddressKHR")
	vtable.GetAccelerationStructureHandleNV                       = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureHandleNV")
	vtable.GetAccelerationStructureMemoryRequirementsNV           = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureMemoryRequirementsNV")
	vtable.GetAccelerationStructureOpaqueCaptureDescriptorDataEXT = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT")
	vtable.GetBufferDeviceAddress                                 = auto_cast GetDeviceProcAddr(device, "vkGetBufferDeviceAddress")
	vtable.GetBufferDeviceAddressEXT                              = auto_cast GetDeviceProcAddr(device, "vkGetBufferDeviceAddressEXT")
	vtable.GetBufferDeviceAddressKHR                              = auto_cast GetDeviceProcAddr(device, "vkGetBufferDeviceAddressKHR")
	vtable.GetBufferMemoryRequirements                            = auto_cast GetDeviceProcAddr(device, "vkGetBufferMemoryRequirements")
	vtable.GetBufferMemoryRequirements2                           = auto_cast GetDeviceProcAddr(device, "vkGetBufferMemoryRequirements2")
	vtable.GetBufferMemoryRequirements2KHR                        = auto_cast GetDeviceProcAddr(device, "vkGetBufferMemoryRequirements2KHR")
	vtable.GetBufferOpaqueCaptureAddress                          = auto_cast GetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureAddress")
	vtable.GetBufferOpaqueCaptureAddressKHR                       = auto_cast GetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureAddressKHR")
	vtable.GetBufferOpaqueCaptureDescriptorDataEXT                = auto_cast GetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureDescriptorDataEXT")
	vtable.GetCalibratedTimestampsEXT                             = auto_cast GetDeviceProcAddr(device, "vkGetCalibratedTimestampsEXT")
	vtable.GetDeferredOperationMaxConcurrencyKHR                  = auto_cast GetDeviceProcAddr(device, "vkGetDeferredOperationMaxConcurrencyKHR")
	vtable.GetDeferredOperationResultKHR                          = auto_cast GetDeviceProcAddr(device, "vkGetDeferredOperationResultKHR")
	vtable.GetDescriptorEXT                                       = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorEXT")
	vtable.GetDescriptorSetHostMappingVALVE                       = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetHostMappingVALVE")
	vtable.GetDescriptorSetLayoutBindingOffsetEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutBindingOffsetEXT")
	vtable.GetDescriptorSetLayoutHostMappingInfoVALVE             = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutHostMappingInfoVALVE")
	vtable.GetDescriptorSetLayoutSizeEXT                          = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSizeEXT")
	vtable.GetDescriptorSetLayoutSupport                          = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSupport")
	vtable.GetDescriptorSetLayoutSupportKHR                       = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSupportKHR")
	vtable.GetDeviceAccelerationStructureCompatibilityKHR         = auto_cast GetDeviceProcAddr(device, "vkGetDeviceAccelerationStructureCompatibilityKHR")
	vtable.GetDeviceBufferMemoryRequirements                      = auto_cast GetDeviceProcAddr(device, "vkGetDeviceBufferMemoryRequirements")
	vtable.GetDeviceBufferMemoryRequirementsKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetDeviceBufferMemoryRequirementsKHR")
	vtable.GetDeviceFaultInfoEXT                                  = auto_cast GetDeviceProcAddr(device, "vkGetDeviceFaultInfoEXT")
	vtable.GetDeviceGroupPeerMemoryFeatures                       = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupPeerMemoryFeatures")
	vtable.GetDeviceGroupPeerMemoryFeaturesKHR                    = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupPeerMemoryFeaturesKHR")
	vtable.GetDeviceGroupPresentCapabilitiesKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupPresentCapabilitiesKHR")
	vtable.GetDeviceGroupSurfacePresentModes2EXT                  = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupSurfacePresentModes2EXT")
	vtable.GetDeviceGroupSurfacePresentModesKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupSurfacePresentModesKHR")
	vtable.GetDeviceImageMemoryRequirements                       = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageMemoryRequirements")
	vtable.GetDeviceImageMemoryRequirementsKHR                    = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageMemoryRequirementsKHR")
	vtable.GetDeviceImageSparseMemoryRequirements                 = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageSparseMemoryRequirements")
	vtable.GetDeviceImageSparseMemoryRequirementsKHR              = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageSparseMemoryRequirementsKHR")
	vtable.GetDeviceMemoryCommitment                              = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMemoryCommitment")
	vtable.GetDeviceMemoryOpaqueCaptureAddress                    = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMemoryOpaqueCaptureAddress")
	vtable.GetDeviceMemoryOpaqueCaptureAddressKHR                 = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMemoryOpaqueCaptureAddressKHR")
	vtable.GetDeviceMicromapCompatibilityEXT                      = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMicromapCompatibilityEXT")
	vtable.GetDeviceProcAddr                                      = auto_cast GetDeviceProcAddr(device, "vkGetDeviceProcAddr")
	vtable.GetDeviceQueue                                         = auto_cast GetDeviceProcAddr(device, "vkGetDeviceQueue")
	vtable.GetDeviceQueue2                                        = auto_cast GetDeviceProcAddr(device, "vkGetDeviceQueue2")
	vtable.GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI          = auto_cast GetDeviceProcAddr(device, "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI")
	vtable.GetDynamicRenderingTilePropertiesQCOM                  = auto_cast GetDeviceProcAddr(device, "vkGetDynamicRenderingTilePropertiesQCOM")
	vtable.GetEventStatus                                         = auto_cast GetDeviceProcAddr(device, "vkGetEventStatus")
	vtable.GetFenceFdKHR                                          = auto_cast GetDeviceProcAddr(device, "vkGetFenceFdKHR")
	vtable.GetFenceStatus                                         = auto_cast GetDeviceProcAddr(device, "vkGetFenceStatus")
	vtable.GetFenceWin32HandleKHR                                 = auto_cast GetDeviceProcAddr(device, "vkGetFenceWin32HandleKHR")
	vtable.GetFramebufferTilePropertiesQCOM                       = auto_cast GetDeviceProcAddr(device, "vkGetFramebufferTilePropertiesQCOM")
	vtable.GetGeneratedCommandsMemoryRequirementsNV               = auto_cast GetDeviceProcAddr(device, "vkGetGeneratedCommandsMemoryRequirementsNV")
	vtable.GetImageDrmFormatModifierPropertiesEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetImageDrmFormatModifierPropertiesEXT")
	vtable.GetImageMemoryRequirements                             = auto_cast GetDeviceProcAddr(device, "vkGetImageMemoryRequirements")
	vtable.GetImageMemoryRequirements2                            = auto_cast GetDeviceProcAddr(device, "vkGetImageMemoryRequirements2")
	vtable.GetImageMemoryRequirements2KHR                         = auto_cast GetDeviceProcAddr(device, "vkGetImageMemoryRequirements2KHR")
	vtable.GetImageOpaqueCaptureDescriptorDataEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetImageOpaqueCaptureDescriptorDataEXT")
	vtable.GetImageSparseMemoryRequirements                       = auto_cast GetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements")
	vtable.GetImageSparseMemoryRequirements2                      = auto_cast GetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements2")
	vtable.GetImageSparseMemoryRequirements2KHR                   = auto_cast GetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements2KHR")
	vtable.GetImageSubresourceLayout                              = auto_cast GetDeviceProcAddr(device, "vkGetImageSubresourceLayout")
	vtable.GetImageSubresourceLayout2EXT                          = auto_cast GetDeviceProcAddr(device, "vkGetImageSubresourceLayout2EXT")
	vtable.GetImageViewAddressNVX                                 = auto_cast GetDeviceProcAddr(device, "vkGetImageViewAddressNVX")
	vtable.GetImageViewHandleNVX                                  = auto_cast GetDeviceProcAddr(device, "vkGetImageViewHandleNVX")
	vtable.GetImageViewOpaqueCaptureDescriptorDataEXT             = auto_cast GetDeviceProcAddr(device, "vkGetImageViewOpaqueCaptureDescriptorDataEXT")
	vtable.GetMemoryFdKHR                                         = auto_cast GetDeviceProcAddr(device, "vkGetMemoryFdKHR")
	vtable.GetMemoryFdPropertiesKHR                               = auto_cast GetDeviceProcAddr(device, "vkGetMemoryFdPropertiesKHR")
	vtable.GetMemoryHostPointerPropertiesEXT                      = auto_cast GetDeviceProcAddr(device, "vkGetMemoryHostPointerPropertiesEXT")
	vtable.GetMemoryRemoteAddressNV                               = auto_cast GetDeviceProcAddr(device, "vkGetMemoryRemoteAddressNV")
	vtable.GetMemoryWin32HandleKHR                                = auto_cast GetDeviceProcAddr(device, "vkGetMemoryWin32HandleKHR")
	vtable.GetMemoryWin32HandleNV                                 = auto_cast GetDeviceProcAddr(device, "vkGetMemoryWin32HandleNV")
	vtable.GetMemoryWin32HandlePropertiesKHR                      = auto_cast GetDeviceProcAddr(device, "vkGetMemoryWin32HandlePropertiesKHR")
	vtable.GetMicromapBuildSizesEXT                               = auto_cast GetDeviceProcAddr(device, "vkGetMicromapBuildSizesEXT")
	vtable.GetPastPresentationTimingGOOGLE                        = auto_cast GetDeviceProcAddr(device, "vkGetPastPresentationTimingGOOGLE")
	vtable.GetPerformanceParameterINTEL                           = auto_cast GetDeviceProcAddr(device, "vkGetPerformanceParameterINTEL")
	vtable.GetPipelineCacheData                                   = auto_cast GetDeviceProcAddr(device, "vkGetPipelineCacheData")
	vtable.GetPipelineExecutableInternalRepresentationsKHR        = auto_cast GetDeviceProcAddr(device, "vkGetPipelineExecutableInternalRepresentationsKHR")
	vtable.GetPipelineExecutablePropertiesKHR                     = auto_cast GetDeviceProcAddr(device, "vkGetPipelineExecutablePropertiesKHR")
	vtable.GetPipelineExecutableStatisticsKHR                     = auto_cast GetDeviceProcAddr(device, "vkGetPipelineExecutableStatisticsKHR")
	vtable.GetPipelinePropertiesEXT                               = auto_cast GetDeviceProcAddr(device, "vkGetPipelinePropertiesEXT")
	vtable.GetPrivateData                                         = auto_cast GetDeviceProcAddr(device, "vkGetPrivateData")
	vtable.GetPrivateDataEXT                                      = auto_cast GetDeviceProcAddr(device, "vkGetPrivateDataEXT")
	vtable.GetQueryPoolResults                                    = auto_cast GetDeviceProcAddr(device, "vkGetQueryPoolResults")
	vtable.GetQueueCheckpointData2NV                              = auto_cast GetDeviceProcAddr(device, "vkGetQueueCheckpointData2NV")
	vtable.GetQueueCheckpointDataNV                               = auto_cast GetDeviceProcAddr(device, "vkGetQueueCheckpointDataNV")
	vtable.GetRayTracingCaptureReplayShaderGroupHandlesKHR        = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR")
	vtable.GetRayTracingShaderGroupHandlesKHR                     = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingShaderGroupHandlesKHR")
	vtable.GetRayTracingShaderGroupHandlesNV                      = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingShaderGroupHandlesNV")
	vtable.GetRayTracingShaderGroupStackSizeKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingShaderGroupStackSizeKHR")
	vtable.GetRefreshCycleDurationGOOGLE                          = auto_cast GetDeviceProcAddr(device, "vkGetRefreshCycleDurationGOOGLE")
	vtable.GetRenderAreaGranularity                               = auto_cast GetDeviceProcAddr(device, "vkGetRenderAreaGranularity")
	vtable.GetSamplerOpaqueCaptureDescriptorDataEXT               = auto_cast GetDeviceProcAddr(device, "vkGetSamplerOpaqueCaptureDescriptorDataEXT")
	vtable.GetSemaphoreCounterValue                               = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreCounterValue")
	vtable.GetSemaphoreCounterValueKHR                            = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreCounterValueKHR")
	vtable.GetSemaphoreFdKHR                                      = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreFdKHR")
	vtable.GetSemaphoreWin32HandleKHR                             = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreWin32HandleKHR")
	vtable.GetShaderBinaryDataEXT                                 = auto_cast GetDeviceProcAddr(device, "vkGetShaderBinaryDataEXT")
	vtable.GetShaderInfoAMD                                       = auto_cast GetDeviceProcAddr(device, "vkGetShaderInfoAMD")
	vtable.GetShaderModuleCreateInfoIdentifierEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetShaderModuleCreateInfoIdentifierEXT")
	vtable.GetShaderModuleIdentifierEXT                           = auto_cast GetDeviceProcAddr(device, "vkGetShaderModuleIdentifierEXT")
	vtable.GetSwapchainCounterEXT                                 = auto_cast GetDeviceProcAddr(device, "vkGetSwapchainCounterEXT")
	vtable.GetSwapchainImagesKHR                                  = auto_cast GetDeviceProcAddr(device, "vkGetSwapchainImagesKHR")
	vtable.GetSwapchainStatusKHR                                  = auto_cast GetDeviceProcAddr(device, "vkGetSwapchainStatusKHR")
	vtable.GetValidationCacheDataEXT                              = auto_cast GetDeviceProcAddr(device, "vkGetValidationCacheDataEXT")
	vtable.GetVideoSessionMemoryRequirementsKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetVideoSessionMemoryRequirementsKHR")
	vtable.ImportFenceFdKHR                                       = auto_cast GetDeviceProcAddr(device, "vkImportFenceFdKHR")
	vtable.ImportFenceWin32HandleKHR                              = auto_cast GetDeviceProcAddr(device, "vkImportFenceWin32HandleKHR")
	vtable.ImportSemaphoreFdKHR                                   = auto_cast GetDeviceProcAddr(device, "vkImportSemaphoreFdKHR")
	vtable.ImportSemaphoreWin32HandleKHR                          = auto_cast GetDeviceProcAddr(device, "vkImportSemaphoreWin32HandleKHR")
	vtable.InitializePerformanceApiINTEL                          = auto_cast GetDeviceProcAddr(device, "vkInitializePerformanceApiINTEL")
	vtable.InvalidateMappedMemoryRanges                           = auto_cast GetDeviceProcAddr(device, "vkInvalidateMappedMemoryRanges")
	vtable.MapMemory                                              = auto_cast GetDeviceProcAddr(device, "vkMapMemory")
	vtable.MapMemory2KHR                                          = auto_cast GetDeviceProcAddr(device, "vkMapMemory2KHR")
	vtable.MergePipelineCaches                                    = auto_cast GetDeviceProcAddr(device, "vkMergePipelineCaches")
	vtable.MergeValidationCachesEXT                               = auto_cast GetDeviceProcAddr(device, "vkMergeValidationCachesEXT")
	vtable.QueueBeginDebugUtilsLabelEXT                           = auto_cast GetDeviceProcAddr(device, "vkQueueBeginDebugUtilsLabelEXT")
	vtable.QueueBindSparse                                        = auto_cast GetDeviceProcAddr(device, "vkQueueBindSparse")
	vtable.QueueEndDebugUtilsLabelEXT                             = auto_cast GetDeviceProcAddr(device, "vkQueueEndDebugUtilsLabelEXT")
	vtable.QueueInsertDebugUtilsLabelEXT                          = auto_cast GetDeviceProcAddr(device, "vkQueueInsertDebugUtilsLabelEXT")
	vtable.QueuePresentKHR                                        = auto_cast GetDeviceProcAddr(device, "vkQueuePresentKHR")
	vtable.QueueSetPerformanceConfigurationINTEL                  = auto_cast GetDeviceProcAddr(device, "vkQueueSetPerformanceConfigurationINTEL")
	vtable.QueueSubmit                                            = auto_cast GetDeviceProcAddr(device, "vkQueueSubmit")
	vtable.QueueSubmit2                                           = auto_cast GetDeviceProcAddr(device, "vkQueueSubmit2")
	vtable.QueueSubmit2KHR                                        = auto_cast GetDeviceProcAddr(device, "vkQueueSubmit2KHR")
	vtable.QueueWaitIdle                                          = auto_cast GetDeviceProcAddr(device, "vkQueueWaitIdle")
	vtable.RegisterDeviceEventEXT                                 = auto_cast GetDeviceProcAddr(device, "vkRegisterDeviceEventEXT")
	vtable.RegisterDisplayEventEXT                                = auto_cast GetDeviceProcAddr(device, "vkRegisterDisplayEventEXT")
	vtable.ReleaseFullScreenExclusiveModeEXT                      = auto_cast GetDeviceProcAddr(device, "vkReleaseFullScreenExclusiveModeEXT")
	vtable.ReleasePerformanceConfigurationINTEL                   = auto_cast GetDeviceProcAddr(device, "vkReleasePerformanceConfigurationINTEL")
	vtable.ReleaseProfilingLockKHR                                = auto_cast GetDeviceProcAddr(device, "vkReleaseProfilingLockKHR")
	vtable.ReleaseSwapchainImagesEXT                              = auto_cast GetDeviceProcAddr(device, "vkReleaseSwapchainImagesEXT")
	vtable.ResetCommandBuffer                                     = auto_cast GetDeviceProcAddr(device, "vkResetCommandBuffer")
	vtable.ResetCommandPool                                       = auto_cast GetDeviceProcAddr(device, "vkResetCommandPool")
	vtable.ResetDescriptorPool                                    = auto_cast GetDeviceProcAddr(device, "vkResetDescriptorPool")
	vtable.ResetEvent                                             = auto_cast GetDeviceProcAddr(device, "vkResetEvent")
	vtable.ResetFences                                            = auto_cast GetDeviceProcAddr(device, "vkResetFences")
	vtable.ResetQueryPool                                         = auto_cast GetDeviceProcAddr(device, "vkResetQueryPool")
	vtable.ResetQueryPoolEXT                                      = auto_cast GetDeviceProcAddr(device, "vkResetQueryPoolEXT")
	vtable.SetDebugUtilsObjectNameEXT                             = auto_cast GetDeviceProcAddr(device, "vkSetDebugUtilsObjectNameEXT")
	vtable.SetDebugUtilsObjectTagEXT                              = auto_cast GetDeviceProcAddr(device, "vkSetDebugUtilsObjectTagEXT")
	vtable.SetDeviceMemoryPriorityEXT                             = auto_cast GetDeviceProcAddr(device, "vkSetDeviceMemoryPriorityEXT")
	vtable.SetEvent                                               = auto_cast GetDeviceProcAddr(device, "vkSetEvent")
	vtable.SetHdrMetadataEXT                                      = auto_cast GetDeviceProcAddr(device, "vkSetHdrMetadataEXT")
	vtable.SetLocalDimmingAMD                                     = auto_cast GetDeviceProcAddr(device, "vkSetLocalDimmingAMD")
	vtable.SetPrivateData                                         = auto_cast GetDeviceProcAddr(device, "vkSetPrivateData")
	vtable.SetPrivateDataEXT                                      = auto_cast GetDeviceProcAddr(device, "vkSetPrivateDataEXT")
	vtable.SignalSemaphore                                        = auto_cast GetDeviceProcAddr(device, "vkSignalSemaphore")
	vtable.SignalSemaphoreKHR                                     = auto_cast GetDeviceProcAddr(device, "vkSignalSemaphoreKHR")
	vtable.TrimCommandPool                                        = auto_cast GetDeviceProcAddr(device, "vkTrimCommandPool")
	vtable.TrimCommandPoolKHR                                     = auto_cast GetDeviceProcAddr(device, "vkTrimCommandPoolKHR")
	vtable.UninitializePerformanceApiINTEL                        = auto_cast GetDeviceProcAddr(device, "vkUninitializePerformanceApiINTEL")
	vtable.UnmapMemory                                            = auto_cast GetDeviceProcAddr(device, "vkUnmapMemory")
	vtable.UnmapMemory2KHR                                        = auto_cast GetDeviceProcAddr(device, "vkUnmapMemory2KHR")
	vtable.UpdateDescriptorSetWithTemplate                        = auto_cast GetDeviceProcAddr(device, "vkUpdateDescriptorSetWithTemplate")
	vtable.UpdateDescriptorSetWithTemplateKHR                     = auto_cast GetDeviceProcAddr(device, "vkUpdateDescriptorSetWithTemplateKHR")
	vtable.UpdateDescriptorSets                                   = auto_cast GetDeviceProcAddr(device, "vkUpdateDescriptorSets")
	vtable.UpdateVideoSessionParametersKHR                        = auto_cast GetDeviceProcAddr(device, "vkUpdateVideoSessionParametersKHR")
	vtable.WaitForFences                                          = auto_cast GetDeviceProcAddr(device, "vkWaitForFences")
	vtable.WaitForPresentKHR                                      = auto_cast GetDeviceProcAddr(device, "vkWaitForPresentKHR")
	vtable.WaitSemaphores                                         = auto_cast GetDeviceProcAddr(device, "vkWaitSemaphores")
	vtable.WaitSemaphoresKHR                                      = auto_cast GetDeviceProcAddr(device, "vkWaitSemaphoresKHR")
	vtable.WriteAccelerationStructuresPropertiesKHR               = auto_cast GetDeviceProcAddr(device, "vkWriteAccelerationStructuresPropertiesKHR")
	vtable.WriteMicromapsPropertiesEXT                            = auto_cast GetDeviceProcAddr(device, "vkWriteMicromapsPropertiesEXT")
}

load_proc_addresses_device :: proc(device: Device) {
	AcquireFullScreenExclusiveModeEXT                      = auto_cast GetDeviceProcAddr(device, "vkAcquireFullScreenExclusiveModeEXT")
	AcquireNextImage2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkAcquireNextImage2KHR")
	AcquireNextImageKHR                                    = auto_cast GetDeviceProcAddr(device, "vkAcquireNextImageKHR")
	AcquirePerformanceConfigurationINTEL                   = auto_cast GetDeviceProcAddr(device, "vkAcquirePerformanceConfigurationINTEL")
	AcquireProfilingLockKHR                                = auto_cast GetDeviceProcAddr(device, "vkAcquireProfilingLockKHR")
	AllocateCommandBuffers                                 = auto_cast GetDeviceProcAddr(device, "vkAllocateCommandBuffers")
	AllocateDescriptorSets                                 = auto_cast GetDeviceProcAddr(device, "vkAllocateDescriptorSets")
	AllocateMemory                                         = auto_cast GetDeviceProcAddr(device, "vkAllocateMemory")
	BeginCommandBuffer                                     = auto_cast GetDeviceProcAddr(device, "vkBeginCommandBuffer")
	BindAccelerationStructureMemoryNV                      = auto_cast GetDeviceProcAddr(device, "vkBindAccelerationStructureMemoryNV")
	BindBufferMemory                                       = auto_cast GetDeviceProcAddr(device, "vkBindBufferMemory")
	BindBufferMemory2                                      = auto_cast GetDeviceProcAddr(device, "vkBindBufferMemory2")
	BindBufferMemory2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkBindBufferMemory2KHR")
	BindImageMemory                                        = auto_cast GetDeviceProcAddr(device, "vkBindImageMemory")
	BindImageMemory2                                       = auto_cast GetDeviceProcAddr(device, "vkBindImageMemory2")
	BindImageMemory2KHR                                    = auto_cast GetDeviceProcAddr(device, "vkBindImageMemory2KHR")
	BindOpticalFlowSessionImageNV                          = auto_cast GetDeviceProcAddr(device, "vkBindOpticalFlowSessionImageNV")
	BindVideoSessionMemoryKHR                              = auto_cast GetDeviceProcAddr(device, "vkBindVideoSessionMemoryKHR")
	BuildAccelerationStructuresKHR                         = auto_cast GetDeviceProcAddr(device, "vkBuildAccelerationStructuresKHR")
	BuildMicromapsEXT                                      = auto_cast GetDeviceProcAddr(device, "vkBuildMicromapsEXT")
	CmdBeginConditionalRenderingEXT                        = auto_cast GetDeviceProcAddr(device, "vkCmdBeginConditionalRenderingEXT")
	CmdBeginDebugUtilsLabelEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdBeginDebugUtilsLabelEXT")
	CmdBeginQuery                                          = auto_cast GetDeviceProcAddr(device, "vkCmdBeginQuery")
	CmdBeginQueryIndexedEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdBeginQueryIndexedEXT")
	CmdBeginRenderPass                                     = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderPass")
	CmdBeginRenderPass2                                    = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderPass2")
	CmdBeginRenderPass2KHR                                 = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderPass2KHR")
	CmdBeginRendering                                      = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRendering")
	CmdBeginRenderingKHR                                   = auto_cast GetDeviceProcAddr(device, "vkCmdBeginRenderingKHR")
	CmdBeginTransformFeedbackEXT                           = auto_cast GetDeviceProcAddr(device, "vkCmdBeginTransformFeedbackEXT")
	CmdBeginVideoCodingKHR                                 = auto_cast GetDeviceProcAddr(device, "vkCmdBeginVideoCodingKHR")
	CmdBindDescriptorBufferEmbeddedSamplersEXT             = auto_cast GetDeviceProcAddr(device, "vkCmdBindDescriptorBufferEmbeddedSamplersEXT")
	CmdBindDescriptorBuffersEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdBindDescriptorBuffersEXT")
	CmdBindDescriptorSets                                  = auto_cast GetDeviceProcAddr(device, "vkCmdBindDescriptorSets")
	CmdBindIndexBuffer                                     = auto_cast GetDeviceProcAddr(device, "vkCmdBindIndexBuffer")
	CmdBindInvocationMaskHUAWEI                            = auto_cast GetDeviceProcAddr(device, "vkCmdBindInvocationMaskHUAWEI")
	CmdBindPipeline                                        = auto_cast GetDeviceProcAddr(device, "vkCmdBindPipeline")
	CmdBindPipelineShaderGroupNV                           = auto_cast GetDeviceProcAddr(device, "vkCmdBindPipelineShaderGroupNV")
	CmdBindShadersEXT                                      = auto_cast GetDeviceProcAddr(device, "vkCmdBindShadersEXT")
	CmdBindShadingRateImageNV                              = auto_cast GetDeviceProcAddr(device, "vkCmdBindShadingRateImageNV")
	CmdBindTransformFeedbackBuffersEXT                     = auto_cast GetDeviceProcAddr(device, "vkCmdBindTransformFeedbackBuffersEXT")
	CmdBindVertexBuffers                                   = auto_cast GetDeviceProcAddr(device, "vkCmdBindVertexBuffers")
	CmdBindVertexBuffers2                                  = auto_cast GetDeviceProcAddr(device, "vkCmdBindVertexBuffers2")
	CmdBindVertexBuffers2EXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdBindVertexBuffers2EXT")
	CmdBlitImage                                           = auto_cast GetDeviceProcAddr(device, "vkCmdBlitImage")
	CmdBlitImage2                                          = auto_cast GetDeviceProcAddr(device, "vkCmdBlitImage2")
	CmdBlitImage2KHR                                       = auto_cast GetDeviceProcAddr(device, "vkCmdBlitImage2KHR")
	CmdBuildAccelerationStructureNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdBuildAccelerationStructureNV")
	CmdBuildAccelerationStructuresIndirectKHR              = auto_cast GetDeviceProcAddr(device, "vkCmdBuildAccelerationStructuresIndirectKHR")
	CmdBuildAccelerationStructuresKHR                      = auto_cast GetDeviceProcAddr(device, "vkCmdBuildAccelerationStructuresKHR")
	CmdBuildMicromapsEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdBuildMicromapsEXT")
	CmdClearAttachments                                    = auto_cast GetDeviceProcAddr(device, "vkCmdClearAttachments")
	CmdClearColorImage                                     = auto_cast GetDeviceProcAddr(device, "vkCmdClearColorImage")
	CmdClearDepthStencilImage                              = auto_cast GetDeviceProcAddr(device, "vkCmdClearDepthStencilImage")
	CmdControlVideoCodingKHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdControlVideoCodingKHR")
	CmdCopyAccelerationStructureKHR                        = auto_cast GetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureKHR")
	CmdCopyAccelerationStructureNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureNV")
	CmdCopyAccelerationStructureToMemoryKHR                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyAccelerationStructureToMemoryKHR")
	CmdCopyBuffer                                          = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBuffer")
	CmdCopyBuffer2                                         = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBuffer2")
	CmdCopyBuffer2KHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBuffer2KHR")
	CmdCopyBufferToImage                                   = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBufferToImage")
	CmdCopyBufferToImage2                                  = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBufferToImage2")
	CmdCopyBufferToImage2KHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdCopyBufferToImage2KHR")
	CmdCopyImage                                           = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImage")
	CmdCopyImage2                                          = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImage2")
	CmdCopyImage2KHR                                       = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImage2KHR")
	CmdCopyImageToBuffer                                   = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImageToBuffer")
	CmdCopyImageToBuffer2                                  = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImageToBuffer2")
	CmdCopyImageToBuffer2KHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdCopyImageToBuffer2KHR")
	CmdCopyMemoryIndirectNV                                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryIndirectNV")
	CmdCopyMemoryToAccelerationStructureKHR                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryToAccelerationStructureKHR")
	CmdCopyMemoryToImageIndirectNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryToImageIndirectNV")
	CmdCopyMemoryToMicromapEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMemoryToMicromapEXT")
	CmdCopyMicromapEXT                                     = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMicromapEXT")
	CmdCopyMicromapToMemoryEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdCopyMicromapToMemoryEXT")
	CmdCopyQueryPoolResults                                = auto_cast GetDeviceProcAddr(device, "vkCmdCopyQueryPoolResults")
	CmdCuLaunchKernelNVX                                   = auto_cast GetDeviceProcAddr(device, "vkCmdCuLaunchKernelNVX")
	CmdDebugMarkerBeginEXT                                 = auto_cast GetDeviceProcAddr(device, "vkCmdDebugMarkerBeginEXT")
	CmdDebugMarkerEndEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdDebugMarkerEndEXT")
	CmdDebugMarkerInsertEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdDebugMarkerInsertEXT")
	CmdDecodeVideoKHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdDecodeVideoKHR")
	CmdDecompressMemoryIndirectCountNV                     = auto_cast GetDeviceProcAddr(device, "vkCmdDecompressMemoryIndirectCountNV")
	CmdDecompressMemoryNV                                  = auto_cast GetDeviceProcAddr(device, "vkCmdDecompressMemoryNV")
	CmdDispatch                                            = auto_cast GetDeviceProcAddr(device, "vkCmdDispatch")
	CmdDispatchBase                                        = auto_cast GetDeviceProcAddr(device, "vkCmdDispatchBase")
	CmdDispatchBaseKHR                                     = auto_cast GetDeviceProcAddr(device, "vkCmdDispatchBaseKHR")
	CmdDispatchIndirect                                    = auto_cast GetDeviceProcAddr(device, "vkCmdDispatchIndirect")
	CmdDraw                                                = auto_cast GetDeviceProcAddr(device, "vkCmdDraw")
	CmdDrawClusterHUAWEI                                   = auto_cast GetDeviceProcAddr(device, "vkCmdDrawClusterHUAWEI")
	CmdDrawClusterIndirectHUAWEI                           = auto_cast GetDeviceProcAddr(device, "vkCmdDrawClusterIndirectHUAWEI")
	CmdDrawIndexed                                         = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexed")
	CmdDrawIndexedIndirect                                 = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirect")
	CmdDrawIndexedIndirectCount                            = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCount")
	CmdDrawIndexedIndirectCountAMD                         = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCountAMD")
	CmdDrawIndexedIndirectCountKHR                         = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndexedIndirectCountKHR")
	CmdDrawIndirect                                        = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirect")
	CmdDrawIndirectByteCountEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectByteCountEXT")
	CmdDrawIndirectCount                                   = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectCount")
	CmdDrawIndirectCountAMD                                = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectCountAMD")
	CmdDrawIndirectCountKHR                                = auto_cast GetDeviceProcAddr(device, "vkCmdDrawIndirectCountKHR")
	CmdDrawMeshTasksEXT                                    = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksEXT")
	CmdDrawMeshTasksIndirectCountEXT                       = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectCountEXT")
	CmdDrawMeshTasksIndirectCountNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectCountNV")
	CmdDrawMeshTasksIndirectEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectEXT")
	CmdDrawMeshTasksIndirectNV                             = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksIndirectNV")
	CmdDrawMeshTasksNV                                     = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMeshTasksNV")
	CmdDrawMultiEXT                                        = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMultiEXT")
	CmdDrawMultiIndexedEXT                                 = auto_cast GetDeviceProcAddr(device, "vkCmdDrawMultiIndexedEXT")
	CmdEndConditionalRenderingEXT                          = auto_cast GetDeviceProcAddr(device, "vkCmdEndConditionalRenderingEXT")
	CmdEndDebugUtilsLabelEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdEndDebugUtilsLabelEXT")
	CmdEndQuery                                            = auto_cast GetDeviceProcAddr(device, "vkCmdEndQuery")
	CmdEndQueryIndexedEXT                                  = auto_cast GetDeviceProcAddr(device, "vkCmdEndQueryIndexedEXT")
	CmdEndRenderPass                                       = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderPass")
	CmdEndRenderPass2                                      = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderPass2")
	CmdEndRenderPass2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderPass2KHR")
	CmdEndRendering                                        = auto_cast GetDeviceProcAddr(device, "vkCmdEndRendering")
	CmdEndRenderingKHR                                     = auto_cast GetDeviceProcAddr(device, "vkCmdEndRenderingKHR")
	CmdEndTransformFeedbackEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdEndTransformFeedbackEXT")
	CmdEndVideoCodingKHR                                   = auto_cast GetDeviceProcAddr(device, "vkCmdEndVideoCodingKHR")
	CmdExecuteCommands                                     = auto_cast GetDeviceProcAddr(device, "vkCmdExecuteCommands")
	CmdExecuteGeneratedCommandsNV                          = auto_cast GetDeviceProcAddr(device, "vkCmdExecuteGeneratedCommandsNV")
	CmdFillBuffer                                          = auto_cast GetDeviceProcAddr(device, "vkCmdFillBuffer")
	CmdInsertDebugUtilsLabelEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdInsertDebugUtilsLabelEXT")
	CmdNextSubpass                                         = auto_cast GetDeviceProcAddr(device, "vkCmdNextSubpass")
	CmdNextSubpass2                                        = auto_cast GetDeviceProcAddr(device, "vkCmdNextSubpass2")
	CmdNextSubpass2KHR                                     = auto_cast GetDeviceProcAddr(device, "vkCmdNextSubpass2KHR")
	CmdOpticalFlowExecuteNV                                = auto_cast GetDeviceProcAddr(device, "vkCmdOpticalFlowExecuteNV")
	CmdPipelineBarrier                                     = auto_cast GetDeviceProcAddr(device, "vkCmdPipelineBarrier")
	CmdPipelineBarrier2                                    = auto_cast GetDeviceProcAddr(device, "vkCmdPipelineBarrier2")
	CmdPipelineBarrier2KHR                                 = auto_cast GetDeviceProcAddr(device, "vkCmdPipelineBarrier2KHR")
	CmdPreprocessGeneratedCommandsNV                       = auto_cast GetDeviceProcAddr(device, "vkCmdPreprocessGeneratedCommandsNV")
	CmdPushConstants                                       = auto_cast GetDeviceProcAddr(device, "vkCmdPushConstants")
	CmdPushDescriptorSetKHR                                = auto_cast GetDeviceProcAddr(device, "vkCmdPushDescriptorSetKHR")
	CmdPushDescriptorSetWithTemplateKHR                    = auto_cast GetDeviceProcAddr(device, "vkCmdPushDescriptorSetWithTemplateKHR")
	CmdResetEvent                                          = auto_cast GetDeviceProcAddr(device, "vkCmdResetEvent")
	CmdResetEvent2                                         = auto_cast GetDeviceProcAddr(device, "vkCmdResetEvent2")
	CmdResetEvent2KHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdResetEvent2KHR")
	CmdResetQueryPool                                      = auto_cast GetDeviceProcAddr(device, "vkCmdResetQueryPool")
	CmdResolveImage                                        = auto_cast GetDeviceProcAddr(device, "vkCmdResolveImage")
	CmdResolveImage2                                       = auto_cast GetDeviceProcAddr(device, "vkCmdResolveImage2")
	CmdResolveImage2KHR                                    = auto_cast GetDeviceProcAddr(device, "vkCmdResolveImage2KHR")
	CmdSetAlphaToCoverageEnableEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetAlphaToCoverageEnableEXT")
	CmdSetAlphaToOneEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetAlphaToOneEnableEXT")
	CmdSetAttachmentFeedbackLoopEnableEXT                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetAttachmentFeedbackLoopEnableEXT")
	CmdSetBlendConstants                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetBlendConstants")
	CmdSetCheckpointNV                                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetCheckpointNV")
	CmdSetCoarseSampleOrderNV                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoarseSampleOrderNV")
	CmdSetColorBlendAdvancedEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorBlendAdvancedEXT")
	CmdSetColorBlendEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorBlendEnableEXT")
	CmdSetColorBlendEquationEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorBlendEquationEXT")
	CmdSetColorWriteMaskEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetColorWriteMaskEXT")
	CmdSetConservativeRasterizationModeEXT                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetConservativeRasterizationModeEXT")
	CmdSetCoverageModulationModeNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageModulationModeNV")
	CmdSetCoverageModulationTableEnableNV                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageModulationTableEnableNV")
	CmdSetCoverageModulationTableNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageModulationTableNV")
	CmdSetCoverageReductionModeNV                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageReductionModeNV")
	CmdSetCoverageToColorEnableNV                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageToColorEnableNV")
	CmdSetCoverageToColorLocationNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetCoverageToColorLocationNV")
	CmdSetCullMode                                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetCullMode")
	CmdSetCullModeEXT                                      = auto_cast GetDeviceProcAddr(device, "vkCmdSetCullModeEXT")
	CmdSetDepthBias                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBias")
	CmdSetDepthBiasEnable                                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBiasEnable")
	CmdSetDepthBiasEnableEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBiasEnableEXT")
	CmdSetDepthBounds                                      = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBounds")
	CmdSetDepthBoundsTestEnable                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBoundsTestEnable")
	CmdSetDepthBoundsTestEnableEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthBoundsTestEnableEXT")
	CmdSetDepthClampEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthClampEnableEXT")
	CmdSetDepthClipEnableEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthClipEnableEXT")
	CmdSetDepthClipNegativeOneToOneEXT                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthClipNegativeOneToOneEXT")
	CmdSetDepthCompareOp                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthCompareOp")
	CmdSetDepthCompareOpEXT                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthCompareOpEXT")
	CmdSetDepthTestEnable                                  = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthTestEnable")
	CmdSetDepthTestEnableEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthTestEnableEXT")
	CmdSetDepthWriteEnable                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthWriteEnable")
	CmdSetDepthWriteEnableEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetDepthWriteEnableEXT")
	CmdSetDescriptorBufferOffsetsEXT                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetDescriptorBufferOffsetsEXT")
	CmdSetDeviceMask                                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetDeviceMask")
	CmdSetDeviceMaskKHR                                    = auto_cast GetDeviceProcAddr(device, "vkCmdSetDeviceMaskKHR")
	CmdSetDiscardRectangleEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetDiscardRectangleEXT")
	CmdSetDiscardRectangleEnableEXT                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetDiscardRectangleEnableEXT")
	CmdSetDiscardRectangleModeEXT                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetDiscardRectangleModeEXT")
	CmdSetEvent                                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetEvent")
	CmdSetEvent2                                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetEvent2")
	CmdSetEvent2KHR                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetEvent2KHR")
	CmdSetExclusiveScissorEnableNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetExclusiveScissorEnableNV")
	CmdSetExclusiveScissorNV                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetExclusiveScissorNV")
	CmdSetExtraPrimitiveOverestimationSizeEXT              = auto_cast GetDeviceProcAddr(device, "vkCmdSetExtraPrimitiveOverestimationSizeEXT")
	CmdSetFragmentShadingRateEnumNV                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetFragmentShadingRateEnumNV")
	CmdSetFragmentShadingRateKHR                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetFragmentShadingRateKHR")
	CmdSetFrontFace                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetFrontFace")
	CmdSetFrontFaceEXT                                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetFrontFaceEXT")
	CmdSetLineRasterizationModeEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineRasterizationModeEXT")
	CmdSetLineStippleEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineStippleEXT")
	CmdSetLineStippleEnableEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineStippleEnableEXT")
	CmdSetLineWidth                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetLineWidth")
	CmdSetLogicOpEXT                                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetLogicOpEXT")
	CmdSetLogicOpEnableEXT                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetLogicOpEnableEXT")
	CmdSetPatchControlPointsEXT                            = auto_cast GetDeviceProcAddr(device, "vkCmdSetPatchControlPointsEXT")
	CmdSetPerformanceMarkerINTEL                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetPerformanceMarkerINTEL")
	CmdSetPerformanceOverrideINTEL                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetPerformanceOverrideINTEL")
	CmdSetPerformanceStreamMarkerINTEL                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetPerformanceStreamMarkerINTEL")
	CmdSetPolygonModeEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetPolygonModeEXT")
	CmdSetPrimitiveRestartEnable                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveRestartEnable")
	CmdSetPrimitiveRestartEnableEXT                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveRestartEnableEXT")
	CmdSetPrimitiveTopology                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveTopology")
	CmdSetPrimitiveTopologyEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetPrimitiveTopologyEXT")
	CmdSetProvokingVertexModeEXT                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetProvokingVertexModeEXT")
	CmdSetRasterizationSamplesEXT                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizationSamplesEXT")
	CmdSetRasterizationStreamEXT                           = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizationStreamEXT")
	CmdSetRasterizerDiscardEnable                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizerDiscardEnable")
	CmdSetRasterizerDiscardEnableEXT                       = auto_cast GetDeviceProcAddr(device, "vkCmdSetRasterizerDiscardEnableEXT")
	CmdSetRayTracingPipelineStackSizeKHR                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetRayTracingPipelineStackSizeKHR")
	CmdSetRepresentativeFragmentTestEnableNV               = auto_cast GetDeviceProcAddr(device, "vkCmdSetRepresentativeFragmentTestEnableNV")
	CmdSetSampleLocationsEXT                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetSampleLocationsEXT")
	CmdSetSampleLocationsEnableEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetSampleLocationsEnableEXT")
	CmdSetSampleMaskEXT                                    = auto_cast GetDeviceProcAddr(device, "vkCmdSetSampleMaskEXT")
	CmdSetScissor                                          = auto_cast GetDeviceProcAddr(device, "vkCmdSetScissor")
	CmdSetScissorWithCount                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetScissorWithCount")
	CmdSetScissorWithCountEXT                              = auto_cast GetDeviceProcAddr(device, "vkCmdSetScissorWithCountEXT")
	CmdSetShadingRateImageEnableNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetShadingRateImageEnableNV")
	CmdSetStencilCompareMask                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilCompareMask")
	CmdSetStencilOp                                        = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilOp")
	CmdSetStencilOpEXT                                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilOpEXT")
	CmdSetStencilReference                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilReference")
	CmdSetStencilTestEnable                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilTestEnable")
	CmdSetStencilTestEnableEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilTestEnableEXT")
	CmdSetStencilWriteMask                                 = auto_cast GetDeviceProcAddr(device, "vkCmdSetStencilWriteMask")
	CmdSetTessellationDomainOriginEXT                      = auto_cast GetDeviceProcAddr(device, "vkCmdSetTessellationDomainOriginEXT")
	CmdSetVertexInputEXT                                   = auto_cast GetDeviceProcAddr(device, "vkCmdSetVertexInputEXT")
	CmdSetViewport                                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewport")
	CmdSetViewportShadingRatePaletteNV                     = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportShadingRatePaletteNV")
	CmdSetViewportSwizzleNV                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportSwizzleNV")
	CmdSetViewportWScalingEnableNV                         = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWScalingEnableNV")
	CmdSetViewportWScalingNV                               = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWScalingNV")
	CmdSetViewportWithCount                                = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWithCount")
	CmdSetViewportWithCountEXT                             = auto_cast GetDeviceProcAddr(device, "vkCmdSetViewportWithCountEXT")
	CmdSubpassShadingHUAWEI                                = auto_cast GetDeviceProcAddr(device, "vkCmdSubpassShadingHUAWEI")
	CmdTraceRaysIndirect2KHR                               = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysIndirect2KHR")
	CmdTraceRaysIndirectKHR                                = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysIndirectKHR")
	CmdTraceRaysKHR                                        = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysKHR")
	CmdTraceRaysNV                                         = auto_cast GetDeviceProcAddr(device, "vkCmdTraceRaysNV")
	CmdUpdateBuffer                                        = auto_cast GetDeviceProcAddr(device, "vkCmdUpdateBuffer")
	CmdWaitEvents                                          = auto_cast GetDeviceProcAddr(device, "vkCmdWaitEvents")
	CmdWaitEvents2                                         = auto_cast GetDeviceProcAddr(device, "vkCmdWaitEvents2")
	CmdWaitEvents2KHR                                      = auto_cast GetDeviceProcAddr(device, "vkCmdWaitEvents2KHR")
	CmdWriteAccelerationStructuresPropertiesKHR            = auto_cast GetDeviceProcAddr(device, "vkCmdWriteAccelerationStructuresPropertiesKHR")
	CmdWriteAccelerationStructuresPropertiesNV             = auto_cast GetDeviceProcAddr(device, "vkCmdWriteAccelerationStructuresPropertiesNV")
	CmdWriteBufferMarker2AMD                               = auto_cast GetDeviceProcAddr(device, "vkCmdWriteBufferMarker2AMD")
	CmdWriteBufferMarkerAMD                                = auto_cast GetDeviceProcAddr(device, "vkCmdWriteBufferMarkerAMD")
	CmdWriteMicromapsPropertiesEXT                         = auto_cast GetDeviceProcAddr(device, "vkCmdWriteMicromapsPropertiesEXT")
	CmdWriteTimestamp                                      = auto_cast GetDeviceProcAddr(device, "vkCmdWriteTimestamp")
	CmdWriteTimestamp2                                     = auto_cast GetDeviceProcAddr(device, "vkCmdWriteTimestamp2")
	CmdWriteTimestamp2KHR                                  = auto_cast GetDeviceProcAddr(device, "vkCmdWriteTimestamp2KHR")
	CompileDeferredNV                                      = auto_cast GetDeviceProcAddr(device, "vkCompileDeferredNV")
	CopyAccelerationStructureKHR                           = auto_cast GetDeviceProcAddr(device, "vkCopyAccelerationStructureKHR")
	CopyAccelerationStructureToMemoryKHR                   = auto_cast GetDeviceProcAddr(device, "vkCopyAccelerationStructureToMemoryKHR")
	CopyMemoryToAccelerationStructureKHR                   = auto_cast GetDeviceProcAddr(device, "vkCopyMemoryToAccelerationStructureKHR")
	CopyMemoryToMicromapEXT                                = auto_cast GetDeviceProcAddr(device, "vkCopyMemoryToMicromapEXT")
	CopyMicromapEXT                                        = auto_cast GetDeviceProcAddr(device, "vkCopyMicromapEXT")
	CopyMicromapToMemoryEXT                                = auto_cast GetDeviceProcAddr(device, "vkCopyMicromapToMemoryEXT")
	CreateAccelerationStructureKHR                         = auto_cast GetDeviceProcAddr(device, "vkCreateAccelerationStructureKHR")
	CreateAccelerationStructureNV                          = auto_cast GetDeviceProcAddr(device, "vkCreateAccelerationStructureNV")
	CreateBuffer                                           = auto_cast GetDeviceProcAddr(device, "vkCreateBuffer")
	CreateBufferView                                       = auto_cast GetDeviceProcAddr(device, "vkCreateBufferView")
	CreateCommandPool                                      = auto_cast GetDeviceProcAddr(device, "vkCreateCommandPool")
	CreateComputePipelines                                 = auto_cast GetDeviceProcAddr(device, "vkCreateComputePipelines")
	CreateCuFunctionNVX                                    = auto_cast GetDeviceProcAddr(device, "vkCreateCuFunctionNVX")
	CreateCuModuleNVX                                      = auto_cast GetDeviceProcAddr(device, "vkCreateCuModuleNVX")
	CreateDeferredOperationKHR                             = auto_cast GetDeviceProcAddr(device, "vkCreateDeferredOperationKHR")
	CreateDescriptorPool                                   = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorPool")
	CreateDescriptorSetLayout                              = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorSetLayout")
	CreateDescriptorUpdateTemplate                         = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorUpdateTemplate")
	CreateDescriptorUpdateTemplateKHR                      = auto_cast GetDeviceProcAddr(device, "vkCreateDescriptorUpdateTemplateKHR")
	CreateEvent                                            = auto_cast GetDeviceProcAddr(device, "vkCreateEvent")
	CreateFence                                            = auto_cast GetDeviceProcAddr(device, "vkCreateFence")
	CreateFramebuffer                                      = auto_cast GetDeviceProcAddr(device, "vkCreateFramebuffer")
	CreateGraphicsPipelines                                = auto_cast GetDeviceProcAddr(device, "vkCreateGraphicsPipelines")
	CreateImage                                            = auto_cast GetDeviceProcAddr(device, "vkCreateImage")
	CreateImageView                                        = auto_cast GetDeviceProcAddr(device, "vkCreateImageView")
	CreateIndirectCommandsLayoutNV                         = auto_cast GetDeviceProcAddr(device, "vkCreateIndirectCommandsLayoutNV")
	CreateMicromapEXT                                      = auto_cast GetDeviceProcAddr(device, "vkCreateMicromapEXT")
	CreateOpticalFlowSessionNV                             = auto_cast GetDeviceProcAddr(device, "vkCreateOpticalFlowSessionNV")
	CreatePipelineCache                                    = auto_cast GetDeviceProcAddr(device, "vkCreatePipelineCache")
	CreatePipelineLayout                                   = auto_cast GetDeviceProcAddr(device, "vkCreatePipelineLayout")
	CreatePrivateDataSlot                                  = auto_cast GetDeviceProcAddr(device, "vkCreatePrivateDataSlot")
	CreatePrivateDataSlotEXT                               = auto_cast GetDeviceProcAddr(device, "vkCreatePrivateDataSlotEXT")
	CreateQueryPool                                        = auto_cast GetDeviceProcAddr(device, "vkCreateQueryPool")
	CreateRayTracingPipelinesKHR                           = auto_cast GetDeviceProcAddr(device, "vkCreateRayTracingPipelinesKHR")
	CreateRayTracingPipelinesNV                            = auto_cast GetDeviceProcAddr(device, "vkCreateRayTracingPipelinesNV")
	CreateRenderPass                                       = auto_cast GetDeviceProcAddr(device, "vkCreateRenderPass")
	CreateRenderPass2                                      = auto_cast GetDeviceProcAddr(device, "vkCreateRenderPass2")
	CreateRenderPass2KHR                                   = auto_cast GetDeviceProcAddr(device, "vkCreateRenderPass2KHR")
	CreateSampler                                          = auto_cast GetDeviceProcAddr(device, "vkCreateSampler")
	CreateSamplerYcbcrConversion                           = auto_cast GetDeviceProcAddr(device, "vkCreateSamplerYcbcrConversion")
	CreateSamplerYcbcrConversionKHR                        = auto_cast GetDeviceProcAddr(device, "vkCreateSamplerYcbcrConversionKHR")
	CreateSemaphore                                        = auto_cast GetDeviceProcAddr(device, "vkCreateSemaphore")
	CreateShaderModule                                     = auto_cast GetDeviceProcAddr(device, "vkCreateShaderModule")
	CreateShadersEXT                                       = auto_cast GetDeviceProcAddr(device, "vkCreateShadersEXT")
	CreateSharedSwapchainsKHR                              = auto_cast GetDeviceProcAddr(device, "vkCreateSharedSwapchainsKHR")
	CreateSwapchainKHR                                     = auto_cast GetDeviceProcAddr(device, "vkCreateSwapchainKHR")
	CreateValidationCacheEXT                               = auto_cast GetDeviceProcAddr(device, "vkCreateValidationCacheEXT")
	CreateVideoSessionKHR                                  = auto_cast GetDeviceProcAddr(device, "vkCreateVideoSessionKHR")
	CreateVideoSessionParametersKHR                        = auto_cast GetDeviceProcAddr(device, "vkCreateVideoSessionParametersKHR")
	DebugMarkerSetObjectNameEXT                            = auto_cast GetDeviceProcAddr(device, "vkDebugMarkerSetObjectNameEXT")
	DebugMarkerSetObjectTagEXT                             = auto_cast GetDeviceProcAddr(device, "vkDebugMarkerSetObjectTagEXT")
	DeferredOperationJoinKHR                               = auto_cast GetDeviceProcAddr(device, "vkDeferredOperationJoinKHR")
	DestroyAccelerationStructureKHR                        = auto_cast GetDeviceProcAddr(device, "vkDestroyAccelerationStructureKHR")
	DestroyAccelerationStructureNV                         = auto_cast GetDeviceProcAddr(device, "vkDestroyAccelerationStructureNV")
	DestroyBuffer                                          = auto_cast GetDeviceProcAddr(device, "vkDestroyBuffer")
	DestroyBufferView                                      = auto_cast GetDeviceProcAddr(device, "vkDestroyBufferView")
	DestroyCommandPool                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyCommandPool")
	DestroyCuFunctionNVX                                   = auto_cast GetDeviceProcAddr(device, "vkDestroyCuFunctionNVX")
	DestroyCuModuleNVX                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyCuModuleNVX")
	DestroyDeferredOperationKHR                            = auto_cast GetDeviceProcAddr(device, "vkDestroyDeferredOperationKHR")
	DestroyDescriptorPool                                  = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorPool")
	DestroyDescriptorSetLayout                             = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorSetLayout")
	DestroyDescriptorUpdateTemplate                        = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorUpdateTemplate")
	DestroyDescriptorUpdateTemplateKHR                     = auto_cast GetDeviceProcAddr(device, "vkDestroyDescriptorUpdateTemplateKHR")
	DestroyDevice                                          = auto_cast GetDeviceProcAddr(device, "vkDestroyDevice")
	DestroyEvent                                           = auto_cast GetDeviceProcAddr(device, "vkDestroyEvent")
	DestroyFence                                           = auto_cast GetDeviceProcAddr(device, "vkDestroyFence")
	DestroyFramebuffer                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyFramebuffer")
	DestroyImage                                           = auto_cast GetDeviceProcAddr(device, "vkDestroyImage")
	DestroyImageView                                       = auto_cast GetDeviceProcAddr(device, "vkDestroyImageView")
	DestroyIndirectCommandsLayoutNV                        = auto_cast GetDeviceProcAddr(device, "vkDestroyIndirectCommandsLayoutNV")
	DestroyMicromapEXT                                     = auto_cast GetDeviceProcAddr(device, "vkDestroyMicromapEXT")
	DestroyOpticalFlowSessionNV                            = auto_cast GetDeviceProcAddr(device, "vkDestroyOpticalFlowSessionNV")
	DestroyPipeline                                        = auto_cast GetDeviceProcAddr(device, "vkDestroyPipeline")
	DestroyPipelineCache                                   = auto_cast GetDeviceProcAddr(device, "vkDestroyPipelineCache")
	DestroyPipelineLayout                                  = auto_cast GetDeviceProcAddr(device, "vkDestroyPipelineLayout")
	DestroyPrivateDataSlot                                 = auto_cast GetDeviceProcAddr(device, "vkDestroyPrivateDataSlot")
	DestroyPrivateDataSlotEXT                              = auto_cast GetDeviceProcAddr(device, "vkDestroyPrivateDataSlotEXT")
	DestroyQueryPool                                       = auto_cast GetDeviceProcAddr(device, "vkDestroyQueryPool")
	DestroyRenderPass                                      = auto_cast GetDeviceProcAddr(device, "vkDestroyRenderPass")
	DestroySampler                                         = auto_cast GetDeviceProcAddr(device, "vkDestroySampler")
	DestroySamplerYcbcrConversion                          = auto_cast GetDeviceProcAddr(device, "vkDestroySamplerYcbcrConversion")
	DestroySamplerYcbcrConversionKHR                       = auto_cast GetDeviceProcAddr(device, "vkDestroySamplerYcbcrConversionKHR")
	DestroySemaphore                                       = auto_cast GetDeviceProcAddr(device, "vkDestroySemaphore")
	DestroyShaderEXT                                       = auto_cast GetDeviceProcAddr(device, "vkDestroyShaderEXT")
	DestroyShaderModule                                    = auto_cast GetDeviceProcAddr(device, "vkDestroyShaderModule")
	DestroySwapchainKHR                                    = auto_cast GetDeviceProcAddr(device, "vkDestroySwapchainKHR")
	DestroyValidationCacheEXT                              = auto_cast GetDeviceProcAddr(device, "vkDestroyValidationCacheEXT")
	DestroyVideoSessionKHR                                 = auto_cast GetDeviceProcAddr(device, "vkDestroyVideoSessionKHR")
	DestroyVideoSessionParametersKHR                       = auto_cast GetDeviceProcAddr(device, "vkDestroyVideoSessionParametersKHR")
	DeviceWaitIdle                                         = auto_cast GetDeviceProcAddr(device, "vkDeviceWaitIdle")
	DisplayPowerControlEXT                                 = auto_cast GetDeviceProcAddr(device, "vkDisplayPowerControlEXT")
	EndCommandBuffer                                       = auto_cast GetDeviceProcAddr(device, "vkEndCommandBuffer")
	ExportMetalObjectsEXT                                  = auto_cast GetDeviceProcAddr(device, "vkExportMetalObjectsEXT")
	FlushMappedMemoryRanges                                = auto_cast GetDeviceProcAddr(device, "vkFlushMappedMemoryRanges")
	FreeCommandBuffers                                     = auto_cast GetDeviceProcAddr(device, "vkFreeCommandBuffers")
	FreeDescriptorSets                                     = auto_cast GetDeviceProcAddr(device, "vkFreeDescriptorSets")
	FreeMemory                                             = auto_cast GetDeviceProcAddr(device, "vkFreeMemory")
	GetAccelerationStructureBuildSizesKHR                  = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureBuildSizesKHR")
	GetAccelerationStructureDeviceAddressKHR               = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureDeviceAddressKHR")
	GetAccelerationStructureHandleNV                       = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureHandleNV")
	GetAccelerationStructureMemoryRequirementsNV           = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureMemoryRequirementsNV")
	GetAccelerationStructureOpaqueCaptureDescriptorDataEXT = auto_cast GetDeviceProcAddr(device, "vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT")
	GetBufferDeviceAddress                                 = auto_cast GetDeviceProcAddr(device, "vkGetBufferDeviceAddress")
	GetBufferDeviceAddressEXT                              = auto_cast GetDeviceProcAddr(device, "vkGetBufferDeviceAddressEXT")
	GetBufferDeviceAddressKHR                              = auto_cast GetDeviceProcAddr(device, "vkGetBufferDeviceAddressKHR")
	GetBufferMemoryRequirements                            = auto_cast GetDeviceProcAddr(device, "vkGetBufferMemoryRequirements")
	GetBufferMemoryRequirements2                           = auto_cast GetDeviceProcAddr(device, "vkGetBufferMemoryRequirements2")
	GetBufferMemoryRequirements2KHR                        = auto_cast GetDeviceProcAddr(device, "vkGetBufferMemoryRequirements2KHR")
	GetBufferOpaqueCaptureAddress                          = auto_cast GetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureAddress")
	GetBufferOpaqueCaptureAddressKHR                       = auto_cast GetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureAddressKHR")
	GetBufferOpaqueCaptureDescriptorDataEXT                = auto_cast GetDeviceProcAddr(device, "vkGetBufferOpaqueCaptureDescriptorDataEXT")
	GetCalibratedTimestampsEXT                             = auto_cast GetDeviceProcAddr(device, "vkGetCalibratedTimestampsEXT")
	GetDeferredOperationMaxConcurrencyKHR                  = auto_cast GetDeviceProcAddr(device, "vkGetDeferredOperationMaxConcurrencyKHR")
	GetDeferredOperationResultKHR                          = auto_cast GetDeviceProcAddr(device, "vkGetDeferredOperationResultKHR")
	GetDescriptorEXT                                       = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorEXT")
	GetDescriptorSetHostMappingVALVE                       = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetHostMappingVALVE")
	GetDescriptorSetLayoutBindingOffsetEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutBindingOffsetEXT")
	GetDescriptorSetLayoutHostMappingInfoVALVE             = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutHostMappingInfoVALVE")
	GetDescriptorSetLayoutSizeEXT                          = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSizeEXT")
	GetDescriptorSetLayoutSupport                          = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSupport")
	GetDescriptorSetLayoutSupportKHR                       = auto_cast GetDeviceProcAddr(device, "vkGetDescriptorSetLayoutSupportKHR")
	GetDeviceAccelerationStructureCompatibilityKHR         = auto_cast GetDeviceProcAddr(device, "vkGetDeviceAccelerationStructureCompatibilityKHR")
	GetDeviceBufferMemoryRequirements                      = auto_cast GetDeviceProcAddr(device, "vkGetDeviceBufferMemoryRequirements")
	GetDeviceBufferMemoryRequirementsKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetDeviceBufferMemoryRequirementsKHR")
	GetDeviceFaultInfoEXT                                  = auto_cast GetDeviceProcAddr(device, "vkGetDeviceFaultInfoEXT")
	GetDeviceGroupPeerMemoryFeatures                       = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupPeerMemoryFeatures")
	GetDeviceGroupPeerMemoryFeaturesKHR                    = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupPeerMemoryFeaturesKHR")
	GetDeviceGroupPresentCapabilitiesKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupPresentCapabilitiesKHR")
	GetDeviceGroupSurfacePresentModes2EXT                  = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupSurfacePresentModes2EXT")
	GetDeviceGroupSurfacePresentModesKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetDeviceGroupSurfacePresentModesKHR")
	GetDeviceImageMemoryRequirements                       = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageMemoryRequirements")
	GetDeviceImageMemoryRequirementsKHR                    = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageMemoryRequirementsKHR")
	GetDeviceImageSparseMemoryRequirements                 = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageSparseMemoryRequirements")
	GetDeviceImageSparseMemoryRequirementsKHR              = auto_cast GetDeviceProcAddr(device, "vkGetDeviceImageSparseMemoryRequirementsKHR")
	GetDeviceMemoryCommitment                              = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMemoryCommitment")
	GetDeviceMemoryOpaqueCaptureAddress                    = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMemoryOpaqueCaptureAddress")
	GetDeviceMemoryOpaqueCaptureAddressKHR                 = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMemoryOpaqueCaptureAddressKHR")
	GetDeviceMicromapCompatibilityEXT                      = auto_cast GetDeviceProcAddr(device, "vkGetDeviceMicromapCompatibilityEXT")
	GetDeviceProcAddr                                      = auto_cast GetDeviceProcAddr(device, "vkGetDeviceProcAddr")
	GetDeviceQueue                                         = auto_cast GetDeviceProcAddr(device, "vkGetDeviceQueue")
	GetDeviceQueue2                                        = auto_cast GetDeviceProcAddr(device, "vkGetDeviceQueue2")
	GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI          = auto_cast GetDeviceProcAddr(device, "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI")
	GetDynamicRenderingTilePropertiesQCOM                  = auto_cast GetDeviceProcAddr(device, "vkGetDynamicRenderingTilePropertiesQCOM")
	GetEventStatus                                         = auto_cast GetDeviceProcAddr(device, "vkGetEventStatus")
	GetFenceFdKHR                                          = auto_cast GetDeviceProcAddr(device, "vkGetFenceFdKHR")
	GetFenceStatus                                         = auto_cast GetDeviceProcAddr(device, "vkGetFenceStatus")
	GetFenceWin32HandleKHR                                 = auto_cast GetDeviceProcAddr(device, "vkGetFenceWin32HandleKHR")
	GetFramebufferTilePropertiesQCOM                       = auto_cast GetDeviceProcAddr(device, "vkGetFramebufferTilePropertiesQCOM")
	GetGeneratedCommandsMemoryRequirementsNV               = auto_cast GetDeviceProcAddr(device, "vkGetGeneratedCommandsMemoryRequirementsNV")
	GetImageDrmFormatModifierPropertiesEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetImageDrmFormatModifierPropertiesEXT")
	GetImageMemoryRequirements                             = auto_cast GetDeviceProcAddr(device, "vkGetImageMemoryRequirements")
	GetImageMemoryRequirements2                            = auto_cast GetDeviceProcAddr(device, "vkGetImageMemoryRequirements2")
	GetImageMemoryRequirements2KHR                         = auto_cast GetDeviceProcAddr(device, "vkGetImageMemoryRequirements2KHR")
	GetImageOpaqueCaptureDescriptorDataEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetImageOpaqueCaptureDescriptorDataEXT")
	GetImageSparseMemoryRequirements                       = auto_cast GetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements")
	GetImageSparseMemoryRequirements2                      = auto_cast GetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements2")
	GetImageSparseMemoryRequirements2KHR                   = auto_cast GetDeviceProcAddr(device, "vkGetImageSparseMemoryRequirements2KHR")
	GetImageSubresourceLayout                              = auto_cast GetDeviceProcAddr(device, "vkGetImageSubresourceLayout")
	GetImageSubresourceLayout2EXT                          = auto_cast GetDeviceProcAddr(device, "vkGetImageSubresourceLayout2EXT")
	GetImageViewAddressNVX                                 = auto_cast GetDeviceProcAddr(device, "vkGetImageViewAddressNVX")
	GetImageViewHandleNVX                                  = auto_cast GetDeviceProcAddr(device, "vkGetImageViewHandleNVX")
	GetImageViewOpaqueCaptureDescriptorDataEXT             = auto_cast GetDeviceProcAddr(device, "vkGetImageViewOpaqueCaptureDescriptorDataEXT")
	GetMemoryFdKHR                                         = auto_cast GetDeviceProcAddr(device, "vkGetMemoryFdKHR")
	GetMemoryFdPropertiesKHR                               = auto_cast GetDeviceProcAddr(device, "vkGetMemoryFdPropertiesKHR")
	GetMemoryHostPointerPropertiesEXT                      = auto_cast GetDeviceProcAddr(device, "vkGetMemoryHostPointerPropertiesEXT")
	GetMemoryRemoteAddressNV                               = auto_cast GetDeviceProcAddr(device, "vkGetMemoryRemoteAddressNV")
	GetMemoryWin32HandleKHR                                = auto_cast GetDeviceProcAddr(device, "vkGetMemoryWin32HandleKHR")
	GetMemoryWin32HandleNV                                 = auto_cast GetDeviceProcAddr(device, "vkGetMemoryWin32HandleNV")
	GetMemoryWin32HandlePropertiesKHR                      = auto_cast GetDeviceProcAddr(device, "vkGetMemoryWin32HandlePropertiesKHR")
	GetMicromapBuildSizesEXT                               = auto_cast GetDeviceProcAddr(device, "vkGetMicromapBuildSizesEXT")
	GetPastPresentationTimingGOOGLE                        = auto_cast GetDeviceProcAddr(device, "vkGetPastPresentationTimingGOOGLE")
	GetPerformanceParameterINTEL                           = auto_cast GetDeviceProcAddr(device, "vkGetPerformanceParameterINTEL")
	GetPipelineCacheData                                   = auto_cast GetDeviceProcAddr(device, "vkGetPipelineCacheData")
	GetPipelineExecutableInternalRepresentationsKHR        = auto_cast GetDeviceProcAddr(device, "vkGetPipelineExecutableInternalRepresentationsKHR")
	GetPipelineExecutablePropertiesKHR                     = auto_cast GetDeviceProcAddr(device, "vkGetPipelineExecutablePropertiesKHR")
	GetPipelineExecutableStatisticsKHR                     = auto_cast GetDeviceProcAddr(device, "vkGetPipelineExecutableStatisticsKHR")
	GetPipelinePropertiesEXT                               = auto_cast GetDeviceProcAddr(device, "vkGetPipelinePropertiesEXT")
	GetPrivateData                                         = auto_cast GetDeviceProcAddr(device, "vkGetPrivateData")
	GetPrivateDataEXT                                      = auto_cast GetDeviceProcAddr(device, "vkGetPrivateDataEXT")
	GetQueryPoolResults                                    = auto_cast GetDeviceProcAddr(device, "vkGetQueryPoolResults")
	GetQueueCheckpointData2NV                              = auto_cast GetDeviceProcAddr(device, "vkGetQueueCheckpointData2NV")
	GetQueueCheckpointDataNV                               = auto_cast GetDeviceProcAddr(device, "vkGetQueueCheckpointDataNV")
	GetRayTracingCaptureReplayShaderGroupHandlesKHR        = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR")
	GetRayTracingShaderGroupHandlesKHR                     = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingShaderGroupHandlesKHR")
	GetRayTracingShaderGroupHandlesNV                      = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingShaderGroupHandlesNV")
	GetRayTracingShaderGroupStackSizeKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetRayTracingShaderGroupStackSizeKHR")
	GetRefreshCycleDurationGOOGLE                          = auto_cast GetDeviceProcAddr(device, "vkGetRefreshCycleDurationGOOGLE")
	GetRenderAreaGranularity                               = auto_cast GetDeviceProcAddr(device, "vkGetRenderAreaGranularity")
	GetSamplerOpaqueCaptureDescriptorDataEXT               = auto_cast GetDeviceProcAddr(device, "vkGetSamplerOpaqueCaptureDescriptorDataEXT")
	GetSemaphoreCounterValue                               = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreCounterValue")
	GetSemaphoreCounterValueKHR                            = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreCounterValueKHR")
	GetSemaphoreFdKHR                                      = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreFdKHR")
	GetSemaphoreWin32HandleKHR                             = auto_cast GetDeviceProcAddr(device, "vkGetSemaphoreWin32HandleKHR")
	GetShaderBinaryDataEXT                                 = auto_cast GetDeviceProcAddr(device, "vkGetShaderBinaryDataEXT")
	GetShaderInfoAMD                                       = auto_cast GetDeviceProcAddr(device, "vkGetShaderInfoAMD")
	GetShaderModuleCreateInfoIdentifierEXT                 = auto_cast GetDeviceProcAddr(device, "vkGetShaderModuleCreateInfoIdentifierEXT")
	GetShaderModuleIdentifierEXT                           = auto_cast GetDeviceProcAddr(device, "vkGetShaderModuleIdentifierEXT")
	GetSwapchainCounterEXT                                 = auto_cast GetDeviceProcAddr(device, "vkGetSwapchainCounterEXT")
	GetSwapchainImagesKHR                                  = auto_cast GetDeviceProcAddr(device, "vkGetSwapchainImagesKHR")
	GetSwapchainStatusKHR                                  = auto_cast GetDeviceProcAddr(device, "vkGetSwapchainStatusKHR")
	GetValidationCacheDataEXT                              = auto_cast GetDeviceProcAddr(device, "vkGetValidationCacheDataEXT")
	GetVideoSessionMemoryRequirementsKHR                   = auto_cast GetDeviceProcAddr(device, "vkGetVideoSessionMemoryRequirementsKHR")
	ImportFenceFdKHR                                       = auto_cast GetDeviceProcAddr(device, "vkImportFenceFdKHR")
	ImportFenceWin32HandleKHR                              = auto_cast GetDeviceProcAddr(device, "vkImportFenceWin32HandleKHR")
	ImportSemaphoreFdKHR                                   = auto_cast GetDeviceProcAddr(device, "vkImportSemaphoreFdKHR")
	ImportSemaphoreWin32HandleKHR                          = auto_cast GetDeviceProcAddr(device, "vkImportSemaphoreWin32HandleKHR")
	InitializePerformanceApiINTEL                          = auto_cast GetDeviceProcAddr(device, "vkInitializePerformanceApiINTEL")
	InvalidateMappedMemoryRanges                           = auto_cast GetDeviceProcAddr(device, "vkInvalidateMappedMemoryRanges")
	MapMemory                                              = auto_cast GetDeviceProcAddr(device, "vkMapMemory")
	MapMemory2KHR                                          = auto_cast GetDeviceProcAddr(device, "vkMapMemory2KHR")
	MergePipelineCaches                                    = auto_cast GetDeviceProcAddr(device, "vkMergePipelineCaches")
	MergeValidationCachesEXT                               = auto_cast GetDeviceProcAddr(device, "vkMergeValidationCachesEXT")
	QueueBeginDebugUtilsLabelEXT                           = auto_cast GetDeviceProcAddr(device, "vkQueueBeginDebugUtilsLabelEXT")
	QueueBindSparse                                        = auto_cast GetDeviceProcAddr(device, "vkQueueBindSparse")
	QueueEndDebugUtilsLabelEXT                             = auto_cast GetDeviceProcAddr(device, "vkQueueEndDebugUtilsLabelEXT")
	QueueInsertDebugUtilsLabelEXT                          = auto_cast GetDeviceProcAddr(device, "vkQueueInsertDebugUtilsLabelEXT")
	QueuePresentKHR                                        = auto_cast GetDeviceProcAddr(device, "vkQueuePresentKHR")
	QueueSetPerformanceConfigurationINTEL                  = auto_cast GetDeviceProcAddr(device, "vkQueueSetPerformanceConfigurationINTEL")
	QueueSubmit                                            = auto_cast GetDeviceProcAddr(device, "vkQueueSubmit")
	QueueSubmit2                                           = auto_cast GetDeviceProcAddr(device, "vkQueueSubmit2")
	QueueSubmit2KHR                                        = auto_cast GetDeviceProcAddr(device, "vkQueueSubmit2KHR")
	QueueWaitIdle                                          = auto_cast GetDeviceProcAddr(device, "vkQueueWaitIdle")
	RegisterDeviceEventEXT                                 = auto_cast GetDeviceProcAddr(device, "vkRegisterDeviceEventEXT")
	RegisterDisplayEventEXT                                = auto_cast GetDeviceProcAddr(device, "vkRegisterDisplayEventEXT")
	ReleaseFullScreenExclusiveModeEXT                      = auto_cast GetDeviceProcAddr(device, "vkReleaseFullScreenExclusiveModeEXT")
	ReleasePerformanceConfigurationINTEL                   = auto_cast GetDeviceProcAddr(device, "vkReleasePerformanceConfigurationINTEL")
	ReleaseProfilingLockKHR                                = auto_cast GetDeviceProcAddr(device, "vkReleaseProfilingLockKHR")
	ReleaseSwapchainImagesEXT                              = auto_cast GetDeviceProcAddr(device, "vkReleaseSwapchainImagesEXT")
	ResetCommandBuffer                                     = auto_cast GetDeviceProcAddr(device, "vkResetCommandBuffer")
	ResetCommandPool                                       = auto_cast GetDeviceProcAddr(device, "vkResetCommandPool")
	ResetDescriptorPool                                    = auto_cast GetDeviceProcAddr(device, "vkResetDescriptorPool")
	ResetEvent                                             = auto_cast GetDeviceProcAddr(device, "vkResetEvent")
	ResetFences                                            = auto_cast GetDeviceProcAddr(device, "vkResetFences")
	ResetQueryPool                                         = auto_cast GetDeviceProcAddr(device, "vkResetQueryPool")
	ResetQueryPoolEXT                                      = auto_cast GetDeviceProcAddr(device, "vkResetQueryPoolEXT")
	SetDebugUtilsObjectNameEXT                             = auto_cast GetDeviceProcAddr(device, "vkSetDebugUtilsObjectNameEXT")
	SetDebugUtilsObjectTagEXT                              = auto_cast GetDeviceProcAddr(device, "vkSetDebugUtilsObjectTagEXT")
	SetDeviceMemoryPriorityEXT                             = auto_cast GetDeviceProcAddr(device, "vkSetDeviceMemoryPriorityEXT")
	SetEvent                                               = auto_cast GetDeviceProcAddr(device, "vkSetEvent")
	SetHdrMetadataEXT                                      = auto_cast GetDeviceProcAddr(device, "vkSetHdrMetadataEXT")
	SetLocalDimmingAMD                                     = auto_cast GetDeviceProcAddr(device, "vkSetLocalDimmingAMD")
	SetPrivateData                                         = auto_cast GetDeviceProcAddr(device, "vkSetPrivateData")
	SetPrivateDataEXT                                      = auto_cast GetDeviceProcAddr(device, "vkSetPrivateDataEXT")
	SignalSemaphore                                        = auto_cast GetDeviceProcAddr(device, "vkSignalSemaphore")
	SignalSemaphoreKHR                                     = auto_cast GetDeviceProcAddr(device, "vkSignalSemaphoreKHR")
	TrimCommandPool                                        = auto_cast GetDeviceProcAddr(device, "vkTrimCommandPool")
	TrimCommandPoolKHR                                     = auto_cast GetDeviceProcAddr(device, "vkTrimCommandPoolKHR")
	UninitializePerformanceApiINTEL                        = auto_cast GetDeviceProcAddr(device, "vkUninitializePerformanceApiINTEL")
	UnmapMemory                                            = auto_cast GetDeviceProcAddr(device, "vkUnmapMemory")
	UnmapMemory2KHR                                        = auto_cast GetDeviceProcAddr(device, "vkUnmapMemory2KHR")
	UpdateDescriptorSetWithTemplate                        = auto_cast GetDeviceProcAddr(device, "vkUpdateDescriptorSetWithTemplate")
	UpdateDescriptorSetWithTemplateKHR                     = auto_cast GetDeviceProcAddr(device, "vkUpdateDescriptorSetWithTemplateKHR")
	UpdateDescriptorSets                                   = auto_cast GetDeviceProcAddr(device, "vkUpdateDescriptorSets")
	UpdateVideoSessionParametersKHR                        = auto_cast GetDeviceProcAddr(device, "vkUpdateVideoSessionParametersKHR")
	WaitForFences                                          = auto_cast GetDeviceProcAddr(device, "vkWaitForFences")
	WaitForPresentKHR                                      = auto_cast GetDeviceProcAddr(device, "vkWaitForPresentKHR")
	WaitSemaphores                                         = auto_cast GetDeviceProcAddr(device, "vkWaitSemaphores")
	WaitSemaphoresKHR                                      = auto_cast GetDeviceProcAddr(device, "vkWaitSemaphoresKHR")
	WriteAccelerationStructuresPropertiesKHR               = auto_cast GetDeviceProcAddr(device, "vkWriteAccelerationStructuresPropertiesKHR")
	WriteMicromapsPropertiesEXT                            = auto_cast GetDeviceProcAddr(device, "vkWriteMicromapsPropertiesEXT")
}

load_proc_addresses_instance :: proc(instance: Instance) {
	AcquireDrmDisplayEXT                                            = auto_cast GetInstanceProcAddr(instance, "vkAcquireDrmDisplayEXT")
	AcquireWinrtDisplayNV                                           = auto_cast GetInstanceProcAddr(instance, "vkAcquireWinrtDisplayNV")
	CreateDebugReportCallbackEXT                                    = auto_cast GetInstanceProcAddr(instance, "vkCreateDebugReportCallbackEXT")
	CreateDebugUtilsMessengerEXT                                    = auto_cast GetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT")
	CreateDevice                                                    = auto_cast GetInstanceProcAddr(instance, "vkCreateDevice")
	CreateDisplayModeKHR                                            = auto_cast GetInstanceProcAddr(instance, "vkCreateDisplayModeKHR")
	CreateDisplayPlaneSurfaceKHR                                    = auto_cast GetInstanceProcAddr(instance, "vkCreateDisplayPlaneSurfaceKHR")
	CreateHeadlessSurfaceEXT                                        = auto_cast GetInstanceProcAddr(instance, "vkCreateHeadlessSurfaceEXT")
	CreateIOSSurfaceMVK                                             = auto_cast GetInstanceProcAddr(instance, "vkCreateIOSSurfaceMVK")
	CreateMacOSSurfaceMVK                                           = auto_cast GetInstanceProcAddr(instance, "vkCreateMacOSSurfaceMVK")
	CreateMetalSurfaceEXT                                           = auto_cast GetInstanceProcAddr(instance, "vkCreateMetalSurfaceEXT")
	CreateWaylandSurfaceKHR                                         = auto_cast GetInstanceProcAddr(instance, "vkCreateWaylandSurfaceKHR")
	CreateWin32SurfaceKHR                                           = auto_cast GetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR")
	DebugReportMessageEXT                                           = auto_cast GetInstanceProcAddr(instance, "vkDebugReportMessageEXT")
	DestroyDebugReportCallbackEXT                                   = auto_cast GetInstanceProcAddr(instance, "vkDestroyDebugReportCallbackEXT")
	DestroyDebugUtilsMessengerEXT                                   = auto_cast GetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT")
	DestroyInstance                                                 = auto_cast GetInstanceProcAddr(instance, "vkDestroyInstance")
	DestroySurfaceKHR                                               = auto_cast GetInstanceProcAddr(instance, "vkDestroySurfaceKHR")
	EnumerateDeviceExtensionProperties                              = auto_cast GetInstanceProcAddr(instance, "vkEnumerateDeviceExtensionProperties")
	EnumerateDeviceLayerProperties                                  = auto_cast GetInstanceProcAddr(instance, "vkEnumerateDeviceLayerProperties")
	EnumeratePhysicalDeviceGroups                                   = auto_cast GetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceGroups")
	EnumeratePhysicalDeviceGroupsKHR                                = auto_cast GetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceGroupsKHR")
	EnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR   = auto_cast GetInstanceProcAddr(instance, "vkEnumeratePhysicalDeviceQueueFamilyPerformanceQueryCountersKHR")
	EnumeratePhysicalDevices                                        = auto_cast GetInstanceProcAddr(instance, "vkEnumeratePhysicalDevices")
	GetDisplayModeProperties2KHR                                    = auto_cast GetInstanceProcAddr(instance, "vkGetDisplayModeProperties2KHR")
	GetDisplayModePropertiesKHR                                     = auto_cast GetInstanceProcAddr(instance, "vkGetDisplayModePropertiesKHR")
	GetDisplayPlaneCapabilities2KHR                                 = auto_cast GetInstanceProcAddr(instance, "vkGetDisplayPlaneCapabilities2KHR")
	GetDisplayPlaneCapabilitiesKHR                                  = auto_cast GetInstanceProcAddr(instance, "vkGetDisplayPlaneCapabilitiesKHR")
	GetDisplayPlaneSupportedDisplaysKHR                             = auto_cast GetInstanceProcAddr(instance, "vkGetDisplayPlaneSupportedDisplaysKHR")
	GetDrmDisplayEXT                                                = auto_cast GetInstanceProcAddr(instance, "vkGetDrmDisplayEXT")
	GetInstanceProcAddrLUNARG                                       = auto_cast GetInstanceProcAddr(instance, "vkGetInstanceProcAddrLUNARG")
	GetPhysicalDeviceCalibrateableTimeDomainsEXT                    = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceCalibrateableTimeDomainsEXT")
	GetPhysicalDeviceCooperativeMatrixPropertiesNV                  = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceCooperativeMatrixPropertiesNV")
	GetPhysicalDeviceDisplayPlaneProperties2KHR                     = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPlaneProperties2KHR")
	GetPhysicalDeviceDisplayPlanePropertiesKHR                      = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPlanePropertiesKHR")
	GetPhysicalDeviceDisplayProperties2KHR                          = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayProperties2KHR")
	GetPhysicalDeviceDisplayPropertiesKHR                           = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceDisplayPropertiesKHR")
	GetPhysicalDeviceExternalBufferProperties                       = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalBufferProperties")
	GetPhysicalDeviceExternalBufferPropertiesKHR                    = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalBufferPropertiesKHR")
	GetPhysicalDeviceExternalFenceProperties                        = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalFenceProperties")
	GetPhysicalDeviceExternalFencePropertiesKHR                     = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalFencePropertiesKHR")
	GetPhysicalDeviceExternalImageFormatPropertiesNV                = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalImageFormatPropertiesNV")
	GetPhysicalDeviceExternalSemaphoreProperties                    = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalSemaphoreProperties")
	GetPhysicalDeviceExternalSemaphorePropertiesKHR                 = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceExternalSemaphorePropertiesKHR")
	GetPhysicalDeviceFeatures                                       = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures")
	GetPhysicalDeviceFeatures2                                      = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures2")
	GetPhysicalDeviceFeatures2KHR                                   = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFeatures2KHR")
	GetPhysicalDeviceFormatProperties                               = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties")
	GetPhysicalDeviceFormatProperties2                              = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties2")
	GetPhysicalDeviceFormatProperties2KHR                           = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFormatProperties2KHR")
	GetPhysicalDeviceFragmentShadingRatesKHR                        = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceFragmentShadingRatesKHR")
	GetPhysicalDeviceImageFormatProperties                          = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties")
	GetPhysicalDeviceImageFormatProperties2                         = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties2")
	GetPhysicalDeviceImageFormatProperties2KHR                      = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceImageFormatProperties2KHR")
	GetPhysicalDeviceMemoryProperties                               = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties")
	GetPhysicalDeviceMemoryProperties2                              = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties2")
	GetPhysicalDeviceMemoryProperties2KHR                           = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMemoryProperties2KHR")
	GetPhysicalDeviceMultisamplePropertiesEXT                       = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceMultisamplePropertiesEXT")
	GetPhysicalDeviceOpticalFlowImageFormatsNV                      = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceOpticalFlowImageFormatsNV")
	GetPhysicalDevicePresentRectanglesKHR                           = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDevicePresentRectanglesKHR")
	GetPhysicalDeviceProperties                                     = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties")
	GetPhysicalDeviceProperties2                                    = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties2")
	GetPhysicalDeviceProperties2KHR                                 = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceProperties2KHR")
	GetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR           = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyPerformanceQueryPassesKHR")
	GetPhysicalDeviceQueueFamilyProperties                          = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties")
	GetPhysicalDeviceQueueFamilyProperties2                         = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties2")
	GetPhysicalDeviceQueueFamilyProperties2KHR                      = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceQueueFamilyProperties2KHR")
	GetPhysicalDeviceSparseImageFormatProperties                    = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties")
	GetPhysicalDeviceSparseImageFormatProperties2                   = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties2")
	GetPhysicalDeviceSparseImageFormatProperties2KHR                = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSparseImageFormatProperties2KHR")
	GetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSupportedFramebufferMixedSamplesCombinationsNV")
	GetPhysicalDeviceSurfaceCapabilities2EXT                        = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilities2EXT")
	GetPhysicalDeviceSurfaceCapabilities2KHR                        = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilities2KHR")
	GetPhysicalDeviceSurfaceCapabilitiesKHR                         = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceCapabilitiesKHR")
	GetPhysicalDeviceSurfaceFormats2KHR                             = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormats2KHR")
	GetPhysicalDeviceSurfaceFormatsKHR                              = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceFormatsKHR")
	GetPhysicalDeviceSurfacePresentModes2EXT                        = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModes2EXT")
	GetPhysicalDeviceSurfacePresentModesKHR                         = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfacePresentModesKHR")
	GetPhysicalDeviceSurfaceSupportKHR                              = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceSurfaceSupportKHR")
	GetPhysicalDeviceToolProperties                                 = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceToolProperties")
	GetPhysicalDeviceToolPropertiesEXT                              = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceToolPropertiesEXT")
	GetPhysicalDeviceVideoCapabilitiesKHR                           = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceVideoCapabilitiesKHR")
	GetPhysicalDeviceVideoFormatPropertiesKHR                       = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceVideoFormatPropertiesKHR")
	GetPhysicalDeviceWaylandPresentationSupportKHR                  = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceWaylandPresentationSupportKHR")
	GetPhysicalDeviceWin32PresentationSupportKHR                    = auto_cast GetInstanceProcAddr(instance, "vkGetPhysicalDeviceWin32PresentationSupportKHR")
	GetWinrtDisplayNV                                               = auto_cast GetInstanceProcAddr(instance, "vkGetWinrtDisplayNV")
	ReleaseDisplayEXT                                               = auto_cast GetInstanceProcAddr(instance, "vkReleaseDisplayEXT")
	SubmitDebugUtilsMessageEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkSubmitDebugUtilsMessageEXT")

	// Device Procedures (may call into dispatch)
	AcquireFullScreenExclusiveModeEXT                      = auto_cast GetInstanceProcAddr(instance, "vkAcquireFullScreenExclusiveModeEXT")
	AcquireNextImage2KHR                                   = auto_cast GetInstanceProcAddr(instance, "vkAcquireNextImage2KHR")
	AcquireNextImageKHR                                    = auto_cast GetInstanceProcAddr(instance, "vkAcquireNextImageKHR")
	AcquirePerformanceConfigurationINTEL                   = auto_cast GetInstanceProcAddr(instance, "vkAcquirePerformanceConfigurationINTEL")
	AcquireProfilingLockKHR                                = auto_cast GetInstanceProcAddr(instance, "vkAcquireProfilingLockKHR")
	AllocateCommandBuffers                                 = auto_cast GetInstanceProcAddr(instance, "vkAllocateCommandBuffers")
	AllocateDescriptorSets                                 = auto_cast GetInstanceProcAddr(instance, "vkAllocateDescriptorSets")
	AllocateMemory                                         = auto_cast GetInstanceProcAddr(instance, "vkAllocateMemory")
	BeginCommandBuffer                                     = auto_cast GetInstanceProcAddr(instance, "vkBeginCommandBuffer")
	BindAccelerationStructureMemoryNV                      = auto_cast GetInstanceProcAddr(instance, "vkBindAccelerationStructureMemoryNV")
	BindBufferMemory                                       = auto_cast GetInstanceProcAddr(instance, "vkBindBufferMemory")
	BindBufferMemory2                                      = auto_cast GetInstanceProcAddr(instance, "vkBindBufferMemory2")
	BindBufferMemory2KHR                                   = auto_cast GetInstanceProcAddr(instance, "vkBindBufferMemory2KHR")
	BindImageMemory                                        = auto_cast GetInstanceProcAddr(instance, "vkBindImageMemory")
	BindImageMemory2                                       = auto_cast GetInstanceProcAddr(instance, "vkBindImageMemory2")
	BindImageMemory2KHR                                    = auto_cast GetInstanceProcAddr(instance, "vkBindImageMemory2KHR")
	BindOpticalFlowSessionImageNV                          = auto_cast GetInstanceProcAddr(instance, "vkBindOpticalFlowSessionImageNV")
	BindVideoSessionMemoryKHR                              = auto_cast GetInstanceProcAddr(instance, "vkBindVideoSessionMemoryKHR")
	BuildAccelerationStructuresKHR                         = auto_cast GetInstanceProcAddr(instance, "vkBuildAccelerationStructuresKHR")
	BuildMicromapsEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkBuildMicromapsEXT")
	CmdBeginConditionalRenderingEXT                        = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginConditionalRenderingEXT")
	CmdBeginDebugUtilsLabelEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginDebugUtilsLabelEXT")
	CmdBeginQuery                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginQuery")
	CmdBeginQueryIndexedEXT                                = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginQueryIndexedEXT")
	CmdBeginRenderPass                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginRenderPass")
	CmdBeginRenderPass2                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginRenderPass2")
	CmdBeginRenderPass2KHR                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginRenderPass2KHR")
	CmdBeginRendering                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginRendering")
	CmdBeginRenderingKHR                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginRenderingKHR")
	CmdBeginTransformFeedbackEXT                           = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginTransformFeedbackEXT")
	CmdBeginVideoCodingKHR                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdBeginVideoCodingKHR")
	CmdBindDescriptorBufferEmbeddedSamplersEXT             = auto_cast GetInstanceProcAddr(instance, "vkCmdBindDescriptorBufferEmbeddedSamplersEXT")
	CmdBindDescriptorBuffersEXT                            = auto_cast GetInstanceProcAddr(instance, "vkCmdBindDescriptorBuffersEXT")
	CmdBindDescriptorSets                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdBindDescriptorSets")
	CmdBindIndexBuffer                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdBindIndexBuffer")
	CmdBindInvocationMaskHUAWEI                            = auto_cast GetInstanceProcAddr(instance, "vkCmdBindInvocationMaskHUAWEI")
	CmdBindPipeline                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdBindPipeline")
	CmdBindPipelineShaderGroupNV                           = auto_cast GetInstanceProcAddr(instance, "vkCmdBindPipelineShaderGroupNV")
	CmdBindShadersEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdBindShadersEXT")
	CmdBindShadingRateImageNV                              = auto_cast GetInstanceProcAddr(instance, "vkCmdBindShadingRateImageNV")
	CmdBindTransformFeedbackBuffersEXT                     = auto_cast GetInstanceProcAddr(instance, "vkCmdBindTransformFeedbackBuffersEXT")
	CmdBindVertexBuffers                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdBindVertexBuffers")
	CmdBindVertexBuffers2                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdBindVertexBuffers2")
	CmdBindVertexBuffers2EXT                               = auto_cast GetInstanceProcAddr(instance, "vkCmdBindVertexBuffers2EXT")
	CmdBlitImage                                           = auto_cast GetInstanceProcAddr(instance, "vkCmdBlitImage")
	CmdBlitImage2                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdBlitImage2")
	CmdBlitImage2KHR                                       = auto_cast GetInstanceProcAddr(instance, "vkCmdBlitImage2KHR")
	CmdBuildAccelerationStructureNV                        = auto_cast GetInstanceProcAddr(instance, "vkCmdBuildAccelerationStructureNV")
	CmdBuildAccelerationStructuresIndirectKHR              = auto_cast GetInstanceProcAddr(instance, "vkCmdBuildAccelerationStructuresIndirectKHR")
	CmdBuildAccelerationStructuresKHR                      = auto_cast GetInstanceProcAddr(instance, "vkCmdBuildAccelerationStructuresKHR")
	CmdBuildMicromapsEXT                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdBuildMicromapsEXT")
	CmdClearAttachments                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdClearAttachments")
	CmdClearColorImage                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdClearColorImage")
	CmdClearDepthStencilImage                              = auto_cast GetInstanceProcAddr(instance, "vkCmdClearDepthStencilImage")
	CmdControlVideoCodingKHR                               = auto_cast GetInstanceProcAddr(instance, "vkCmdControlVideoCodingKHR")
	CmdCopyAccelerationStructureKHR                        = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyAccelerationStructureKHR")
	CmdCopyAccelerationStructureNV                         = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyAccelerationStructureNV")
	CmdCopyAccelerationStructureToMemoryKHR                = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyAccelerationStructureToMemoryKHR")
	CmdCopyBuffer                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyBuffer")
	CmdCopyBuffer2                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyBuffer2")
	CmdCopyBuffer2KHR                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyBuffer2KHR")
	CmdCopyBufferToImage                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyBufferToImage")
	CmdCopyBufferToImage2                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyBufferToImage2")
	CmdCopyBufferToImage2KHR                               = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyBufferToImage2KHR")
	CmdCopyImage                                           = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyImage")
	CmdCopyImage2                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyImage2")
	CmdCopyImage2KHR                                       = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyImage2KHR")
	CmdCopyImageToBuffer                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyImageToBuffer")
	CmdCopyImageToBuffer2                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyImageToBuffer2")
	CmdCopyImageToBuffer2KHR                               = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyImageToBuffer2KHR")
	CmdCopyMemoryIndirectNV                                = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyMemoryIndirectNV")
	CmdCopyMemoryToAccelerationStructureKHR                = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyMemoryToAccelerationStructureKHR")
	CmdCopyMemoryToImageIndirectNV                         = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyMemoryToImageIndirectNV")
	CmdCopyMemoryToMicromapEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyMemoryToMicromapEXT")
	CmdCopyMicromapEXT                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyMicromapEXT")
	CmdCopyMicromapToMemoryEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyMicromapToMemoryEXT")
	CmdCopyQueryPoolResults                                = auto_cast GetInstanceProcAddr(instance, "vkCmdCopyQueryPoolResults")
	CmdCuLaunchKernelNVX                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdCuLaunchKernelNVX")
	CmdDebugMarkerBeginEXT                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdDebugMarkerBeginEXT")
	CmdDebugMarkerEndEXT                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdDebugMarkerEndEXT")
	CmdDebugMarkerInsertEXT                                = auto_cast GetInstanceProcAddr(instance, "vkCmdDebugMarkerInsertEXT")
	CmdDecodeVideoKHR                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdDecodeVideoKHR")
	CmdDecompressMemoryIndirectCountNV                     = auto_cast GetInstanceProcAddr(instance, "vkCmdDecompressMemoryIndirectCountNV")
	CmdDecompressMemoryNV                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdDecompressMemoryNV")
	CmdDispatch                                            = auto_cast GetInstanceProcAddr(instance, "vkCmdDispatch")
	CmdDispatchBase                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdDispatchBase")
	CmdDispatchBaseKHR                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdDispatchBaseKHR")
	CmdDispatchIndirect                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdDispatchIndirect")
	CmdDraw                                                = auto_cast GetInstanceProcAddr(instance, "vkCmdDraw")
	CmdDrawClusterHUAWEI                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawClusterHUAWEI")
	CmdDrawClusterIndirectHUAWEI                           = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawClusterIndirectHUAWEI")
	CmdDrawIndexed                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndexed")
	CmdDrawIndexedIndirect                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndexedIndirect")
	CmdDrawIndexedIndirectCount                            = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndexedIndirectCount")
	CmdDrawIndexedIndirectCountAMD                         = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndexedIndirectCountAMD")
	CmdDrawIndexedIndirectCountKHR                         = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndexedIndirectCountKHR")
	CmdDrawIndirect                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndirect")
	CmdDrawIndirectByteCountEXT                            = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndirectByteCountEXT")
	CmdDrawIndirectCount                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndirectCount")
	CmdDrawIndirectCountAMD                                = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndirectCountAMD")
	CmdDrawIndirectCountKHR                                = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawIndirectCountKHR")
	CmdDrawMeshTasksEXT                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMeshTasksEXT")
	CmdDrawMeshTasksIndirectCountEXT                       = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMeshTasksIndirectCountEXT")
	CmdDrawMeshTasksIndirectCountNV                        = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMeshTasksIndirectCountNV")
	CmdDrawMeshTasksIndirectEXT                            = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMeshTasksIndirectEXT")
	CmdDrawMeshTasksIndirectNV                             = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMeshTasksIndirectNV")
	CmdDrawMeshTasksNV                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMeshTasksNV")
	CmdDrawMultiEXT                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMultiEXT")
	CmdDrawMultiIndexedEXT                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdDrawMultiIndexedEXT")
	CmdEndConditionalRenderingEXT                          = auto_cast GetInstanceProcAddr(instance, "vkCmdEndConditionalRenderingEXT")
	CmdEndDebugUtilsLabelEXT                               = auto_cast GetInstanceProcAddr(instance, "vkCmdEndDebugUtilsLabelEXT")
	CmdEndQuery                                            = auto_cast GetInstanceProcAddr(instance, "vkCmdEndQuery")
	CmdEndQueryIndexedEXT                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdEndQueryIndexedEXT")
	CmdEndRenderPass                                       = auto_cast GetInstanceProcAddr(instance, "vkCmdEndRenderPass")
	CmdEndRenderPass2                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdEndRenderPass2")
	CmdEndRenderPass2KHR                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdEndRenderPass2KHR")
	CmdEndRendering                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdEndRendering")
	CmdEndRenderingKHR                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdEndRenderingKHR")
	CmdEndTransformFeedbackEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdEndTransformFeedbackEXT")
	CmdEndVideoCodingKHR                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdEndVideoCodingKHR")
	CmdExecuteCommands                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdExecuteCommands")
	CmdExecuteGeneratedCommandsNV                          = auto_cast GetInstanceProcAddr(instance, "vkCmdExecuteGeneratedCommandsNV")
	CmdFillBuffer                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdFillBuffer")
	CmdInsertDebugUtilsLabelEXT                            = auto_cast GetInstanceProcAddr(instance, "vkCmdInsertDebugUtilsLabelEXT")
	CmdNextSubpass                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdNextSubpass")
	CmdNextSubpass2                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdNextSubpass2")
	CmdNextSubpass2KHR                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdNextSubpass2KHR")
	CmdOpticalFlowExecuteNV                                = auto_cast GetInstanceProcAddr(instance, "vkCmdOpticalFlowExecuteNV")
	CmdPipelineBarrier                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdPipelineBarrier")
	CmdPipelineBarrier2                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdPipelineBarrier2")
	CmdPipelineBarrier2KHR                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdPipelineBarrier2KHR")
	CmdPreprocessGeneratedCommandsNV                       = auto_cast GetInstanceProcAddr(instance, "vkCmdPreprocessGeneratedCommandsNV")
	CmdPushConstants                                       = auto_cast GetInstanceProcAddr(instance, "vkCmdPushConstants")
	CmdPushDescriptorSetKHR                                = auto_cast GetInstanceProcAddr(instance, "vkCmdPushDescriptorSetKHR")
	CmdPushDescriptorSetWithTemplateKHR                    = auto_cast GetInstanceProcAddr(instance, "vkCmdPushDescriptorSetWithTemplateKHR")
	CmdResetEvent                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdResetEvent")
	CmdResetEvent2                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdResetEvent2")
	CmdResetEvent2KHR                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdResetEvent2KHR")
	CmdResetQueryPool                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdResetQueryPool")
	CmdResolveImage                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdResolveImage")
	CmdResolveImage2                                       = auto_cast GetInstanceProcAddr(instance, "vkCmdResolveImage2")
	CmdResolveImage2KHR                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdResolveImage2KHR")
	CmdSetAlphaToCoverageEnableEXT                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetAlphaToCoverageEnableEXT")
	CmdSetAlphaToOneEnableEXT                              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetAlphaToOneEnableEXT")
	CmdSetAttachmentFeedbackLoopEnableEXT                  = auto_cast GetInstanceProcAddr(instance, "vkCmdSetAttachmentFeedbackLoopEnableEXT")
	CmdSetBlendConstants                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdSetBlendConstants")
	CmdSetCheckpointNV                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCheckpointNV")
	CmdSetCoarseSampleOrderNV                              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCoarseSampleOrderNV")
	CmdSetColorBlendAdvancedEXT                            = auto_cast GetInstanceProcAddr(instance, "vkCmdSetColorBlendAdvancedEXT")
	CmdSetColorBlendEnableEXT                              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetColorBlendEnableEXT")
	CmdSetColorBlendEquationEXT                            = auto_cast GetInstanceProcAddr(instance, "vkCmdSetColorBlendEquationEXT")
	CmdSetColorWriteMaskEXT                                = auto_cast GetInstanceProcAddr(instance, "vkCmdSetColorWriteMaskEXT")
	CmdSetConservativeRasterizationModeEXT                 = auto_cast GetInstanceProcAddr(instance, "vkCmdSetConservativeRasterizationModeEXT")
	CmdSetCoverageModulationModeNV                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCoverageModulationModeNV")
	CmdSetCoverageModulationTableEnableNV                  = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCoverageModulationTableEnableNV")
	CmdSetCoverageModulationTableNV                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCoverageModulationTableNV")
	CmdSetCoverageReductionModeNV                          = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCoverageReductionModeNV")
	CmdSetCoverageToColorEnableNV                          = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCoverageToColorEnableNV")
	CmdSetCoverageToColorLocationNV                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCoverageToColorLocationNV")
	CmdSetCullMode                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCullMode")
	CmdSetCullModeEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdSetCullModeEXT")
	CmdSetDepthBias                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthBias")
	CmdSetDepthBiasEnable                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthBiasEnable")
	CmdSetDepthBiasEnableEXT                               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthBiasEnableEXT")
	CmdSetDepthBounds                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthBounds")
	CmdSetDepthBoundsTestEnable                            = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthBoundsTestEnable")
	CmdSetDepthBoundsTestEnableEXT                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthBoundsTestEnableEXT")
	CmdSetDepthClampEnableEXT                              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthClampEnableEXT")
	CmdSetDepthClipEnableEXT                               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthClipEnableEXT")
	CmdSetDepthClipNegativeOneToOneEXT                     = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthClipNegativeOneToOneEXT")
	CmdSetDepthCompareOp                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthCompareOp")
	CmdSetDepthCompareOpEXT                                = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthCompareOpEXT")
	CmdSetDepthTestEnable                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthTestEnable")
	CmdSetDepthTestEnableEXT                               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthTestEnableEXT")
	CmdSetDepthWriteEnable                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthWriteEnable")
	CmdSetDepthWriteEnableEXT                              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDepthWriteEnableEXT")
	CmdSetDescriptorBufferOffsetsEXT                       = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDescriptorBufferOffsetsEXT")
	CmdSetDeviceMask                                       = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDeviceMask")
	CmdSetDeviceMaskKHR                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDeviceMaskKHR")
	CmdSetDiscardRectangleEXT                              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDiscardRectangleEXT")
	CmdSetDiscardRectangleEnableEXT                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDiscardRectangleEnableEXT")
	CmdSetDiscardRectangleModeEXT                          = auto_cast GetInstanceProcAddr(instance, "vkCmdSetDiscardRectangleModeEXT")
	CmdSetEvent                                            = auto_cast GetInstanceProcAddr(instance, "vkCmdSetEvent")
	CmdSetEvent2                                           = auto_cast GetInstanceProcAddr(instance, "vkCmdSetEvent2")
	CmdSetEvent2KHR                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetEvent2KHR")
	CmdSetExclusiveScissorEnableNV                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetExclusiveScissorEnableNV")
	CmdSetExclusiveScissorNV                               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetExclusiveScissorNV")
	CmdSetExtraPrimitiveOverestimationSizeEXT              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetExtraPrimitiveOverestimationSizeEXT")
	CmdSetFragmentShadingRateEnumNV                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetFragmentShadingRateEnumNV")
	CmdSetFragmentShadingRateKHR                           = auto_cast GetInstanceProcAddr(instance, "vkCmdSetFragmentShadingRateKHR")
	CmdSetFrontFace                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetFrontFace")
	CmdSetFrontFaceEXT                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdSetFrontFaceEXT")
	CmdSetLineRasterizationModeEXT                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetLineRasterizationModeEXT")
	CmdSetLineStippleEXT                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdSetLineStippleEXT")
	CmdSetLineStippleEnableEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdSetLineStippleEnableEXT")
	CmdSetLineWidth                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetLineWidth")
	CmdSetLogicOpEXT                                       = auto_cast GetInstanceProcAddr(instance, "vkCmdSetLogicOpEXT")
	CmdSetLogicOpEnableEXT                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdSetLogicOpEnableEXT")
	CmdSetPatchControlPointsEXT                            = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPatchControlPointsEXT")
	CmdSetPerformanceMarkerINTEL                           = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPerformanceMarkerINTEL")
	CmdSetPerformanceOverrideINTEL                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPerformanceOverrideINTEL")
	CmdSetPerformanceStreamMarkerINTEL                     = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPerformanceStreamMarkerINTEL")
	CmdSetPolygonModeEXT                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPolygonModeEXT")
	CmdSetPrimitiveRestartEnable                           = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPrimitiveRestartEnable")
	CmdSetPrimitiveRestartEnableEXT                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPrimitiveRestartEnableEXT")
	CmdSetPrimitiveTopology                                = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPrimitiveTopology")
	CmdSetPrimitiveTopologyEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdSetPrimitiveTopologyEXT")
	CmdSetProvokingVertexModeEXT                           = auto_cast GetInstanceProcAddr(instance, "vkCmdSetProvokingVertexModeEXT")
	CmdSetRasterizationSamplesEXT                          = auto_cast GetInstanceProcAddr(instance, "vkCmdSetRasterizationSamplesEXT")
	CmdSetRasterizationStreamEXT                           = auto_cast GetInstanceProcAddr(instance, "vkCmdSetRasterizationStreamEXT")
	CmdSetRasterizerDiscardEnable                          = auto_cast GetInstanceProcAddr(instance, "vkCmdSetRasterizerDiscardEnable")
	CmdSetRasterizerDiscardEnableEXT                       = auto_cast GetInstanceProcAddr(instance, "vkCmdSetRasterizerDiscardEnableEXT")
	CmdSetRayTracingPipelineStackSizeKHR                   = auto_cast GetInstanceProcAddr(instance, "vkCmdSetRayTracingPipelineStackSizeKHR")
	CmdSetRepresentativeFragmentTestEnableNV               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetRepresentativeFragmentTestEnableNV")
	CmdSetSampleLocationsEXT                               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetSampleLocationsEXT")
	CmdSetSampleLocationsEnableEXT                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetSampleLocationsEnableEXT")
	CmdSetSampleMaskEXT                                    = auto_cast GetInstanceProcAddr(instance, "vkCmdSetSampleMaskEXT")
	CmdSetScissor                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdSetScissor")
	CmdSetScissorWithCount                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdSetScissorWithCount")
	CmdSetScissorWithCountEXT                              = auto_cast GetInstanceProcAddr(instance, "vkCmdSetScissorWithCountEXT")
	CmdSetShadingRateImageEnableNV                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetShadingRateImageEnableNV")
	CmdSetStencilCompareMask                               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetStencilCompareMask")
	CmdSetStencilOp                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdSetStencilOp")
	CmdSetStencilOpEXT                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdSetStencilOpEXT")
	CmdSetStencilReference                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdSetStencilReference")
	CmdSetStencilTestEnable                                = auto_cast GetInstanceProcAddr(instance, "vkCmdSetStencilTestEnable")
	CmdSetStencilTestEnableEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdSetStencilTestEnableEXT")
	CmdSetStencilWriteMask                                 = auto_cast GetInstanceProcAddr(instance, "vkCmdSetStencilWriteMask")
	CmdSetTessellationDomainOriginEXT                      = auto_cast GetInstanceProcAddr(instance, "vkCmdSetTessellationDomainOriginEXT")
	CmdSetVertexInputEXT                                   = auto_cast GetInstanceProcAddr(instance, "vkCmdSetVertexInputEXT")
	CmdSetViewport                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetViewport")
	CmdSetViewportShadingRatePaletteNV                     = auto_cast GetInstanceProcAddr(instance, "vkCmdSetViewportShadingRatePaletteNV")
	CmdSetViewportSwizzleNV                                = auto_cast GetInstanceProcAddr(instance, "vkCmdSetViewportSwizzleNV")
	CmdSetViewportWScalingEnableNV                         = auto_cast GetInstanceProcAddr(instance, "vkCmdSetViewportWScalingEnableNV")
	CmdSetViewportWScalingNV                               = auto_cast GetInstanceProcAddr(instance, "vkCmdSetViewportWScalingNV")
	CmdSetViewportWithCount                                = auto_cast GetInstanceProcAddr(instance, "vkCmdSetViewportWithCount")
	CmdSetViewportWithCountEXT                             = auto_cast GetInstanceProcAddr(instance, "vkCmdSetViewportWithCountEXT")
	CmdSubpassShadingHUAWEI                                = auto_cast GetInstanceProcAddr(instance, "vkCmdSubpassShadingHUAWEI")
	CmdTraceRaysIndirect2KHR                               = auto_cast GetInstanceProcAddr(instance, "vkCmdTraceRaysIndirect2KHR")
	CmdTraceRaysIndirectKHR                                = auto_cast GetInstanceProcAddr(instance, "vkCmdTraceRaysIndirectKHR")
	CmdTraceRaysKHR                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdTraceRaysKHR")
	CmdTraceRaysNV                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdTraceRaysNV")
	CmdUpdateBuffer                                        = auto_cast GetInstanceProcAddr(instance, "vkCmdUpdateBuffer")
	CmdWaitEvents                                          = auto_cast GetInstanceProcAddr(instance, "vkCmdWaitEvents")
	CmdWaitEvents2                                         = auto_cast GetInstanceProcAddr(instance, "vkCmdWaitEvents2")
	CmdWaitEvents2KHR                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdWaitEvents2KHR")
	CmdWriteAccelerationStructuresPropertiesKHR            = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteAccelerationStructuresPropertiesKHR")
	CmdWriteAccelerationStructuresPropertiesNV             = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteAccelerationStructuresPropertiesNV")
	CmdWriteBufferMarker2AMD                               = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteBufferMarker2AMD")
	CmdWriteBufferMarkerAMD                                = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteBufferMarkerAMD")
	CmdWriteMicromapsPropertiesEXT                         = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteMicromapsPropertiesEXT")
	CmdWriteTimestamp                                      = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteTimestamp")
	CmdWriteTimestamp2                                     = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteTimestamp2")
	CmdWriteTimestamp2KHR                                  = auto_cast GetInstanceProcAddr(instance, "vkCmdWriteTimestamp2KHR")
	CompileDeferredNV                                      = auto_cast GetInstanceProcAddr(instance, "vkCompileDeferredNV")
	CopyAccelerationStructureKHR                           = auto_cast GetInstanceProcAddr(instance, "vkCopyAccelerationStructureKHR")
	CopyAccelerationStructureToMemoryKHR                   = auto_cast GetInstanceProcAddr(instance, "vkCopyAccelerationStructureToMemoryKHR")
	CopyMemoryToAccelerationStructureKHR                   = auto_cast GetInstanceProcAddr(instance, "vkCopyMemoryToAccelerationStructureKHR")
	CopyMemoryToMicromapEXT                                = auto_cast GetInstanceProcAddr(instance, "vkCopyMemoryToMicromapEXT")
	CopyMicromapEXT                                        = auto_cast GetInstanceProcAddr(instance, "vkCopyMicromapEXT")
	CopyMicromapToMemoryEXT                                = auto_cast GetInstanceProcAddr(instance, "vkCopyMicromapToMemoryEXT")
	CreateAccelerationStructureKHR                         = auto_cast GetInstanceProcAddr(instance, "vkCreateAccelerationStructureKHR")
	CreateAccelerationStructureNV                          = auto_cast GetInstanceProcAddr(instance, "vkCreateAccelerationStructureNV")
	CreateBuffer                                           = auto_cast GetInstanceProcAddr(instance, "vkCreateBuffer")
	CreateBufferView                                       = auto_cast GetInstanceProcAddr(instance, "vkCreateBufferView")
	CreateCommandPool                                      = auto_cast GetInstanceProcAddr(instance, "vkCreateCommandPool")
	CreateComputePipelines                                 = auto_cast GetInstanceProcAddr(instance, "vkCreateComputePipelines")
	CreateCuFunctionNVX                                    = auto_cast GetInstanceProcAddr(instance, "vkCreateCuFunctionNVX")
	CreateCuModuleNVX                                      = auto_cast GetInstanceProcAddr(instance, "vkCreateCuModuleNVX")
	CreateDeferredOperationKHR                             = auto_cast GetInstanceProcAddr(instance, "vkCreateDeferredOperationKHR")
	CreateDescriptorPool                                   = auto_cast GetInstanceProcAddr(instance, "vkCreateDescriptorPool")
	CreateDescriptorSetLayout                              = auto_cast GetInstanceProcAddr(instance, "vkCreateDescriptorSetLayout")
	CreateDescriptorUpdateTemplate                         = auto_cast GetInstanceProcAddr(instance, "vkCreateDescriptorUpdateTemplate")
	CreateDescriptorUpdateTemplateKHR                      = auto_cast GetInstanceProcAddr(instance, "vkCreateDescriptorUpdateTemplateKHR")
	CreateEvent                                            = auto_cast GetInstanceProcAddr(instance, "vkCreateEvent")
	CreateFence                                            = auto_cast GetInstanceProcAddr(instance, "vkCreateFence")
	CreateFramebuffer                                      = auto_cast GetInstanceProcAddr(instance, "vkCreateFramebuffer")
	CreateGraphicsPipelines                                = auto_cast GetInstanceProcAddr(instance, "vkCreateGraphicsPipelines")
	CreateImage                                            = auto_cast GetInstanceProcAddr(instance, "vkCreateImage")
	CreateImageView                                        = auto_cast GetInstanceProcAddr(instance, "vkCreateImageView")
	CreateIndirectCommandsLayoutNV                         = auto_cast GetInstanceProcAddr(instance, "vkCreateIndirectCommandsLayoutNV")
	CreateMicromapEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkCreateMicromapEXT")
	CreateOpticalFlowSessionNV                             = auto_cast GetInstanceProcAddr(instance, "vkCreateOpticalFlowSessionNV")
	CreatePipelineCache                                    = auto_cast GetInstanceProcAddr(instance, "vkCreatePipelineCache")
	CreatePipelineLayout                                   = auto_cast GetInstanceProcAddr(instance, "vkCreatePipelineLayout")
	CreatePrivateDataSlot                                  = auto_cast GetInstanceProcAddr(instance, "vkCreatePrivateDataSlot")
	CreatePrivateDataSlotEXT                               = auto_cast GetInstanceProcAddr(instance, "vkCreatePrivateDataSlotEXT")
	CreateQueryPool                                        = auto_cast GetInstanceProcAddr(instance, "vkCreateQueryPool")
	CreateRayTracingPipelinesKHR                           = auto_cast GetInstanceProcAddr(instance, "vkCreateRayTracingPipelinesKHR")
	CreateRayTracingPipelinesNV                            = auto_cast GetInstanceProcAddr(instance, "vkCreateRayTracingPipelinesNV")
	CreateRenderPass                                       = auto_cast GetInstanceProcAddr(instance, "vkCreateRenderPass")
	CreateRenderPass2                                      = auto_cast GetInstanceProcAddr(instance, "vkCreateRenderPass2")
	CreateRenderPass2KHR                                   = auto_cast GetInstanceProcAddr(instance, "vkCreateRenderPass2KHR")
	CreateSampler                                          = auto_cast GetInstanceProcAddr(instance, "vkCreateSampler")
	CreateSamplerYcbcrConversion                           = auto_cast GetInstanceProcAddr(instance, "vkCreateSamplerYcbcrConversion")
	CreateSamplerYcbcrConversionKHR                        = auto_cast GetInstanceProcAddr(instance, "vkCreateSamplerYcbcrConversionKHR")
	CreateSemaphore                                        = auto_cast GetInstanceProcAddr(instance, "vkCreateSemaphore")
	CreateShaderModule                                     = auto_cast GetInstanceProcAddr(instance, "vkCreateShaderModule")
	CreateShadersEXT                                       = auto_cast GetInstanceProcAddr(instance, "vkCreateShadersEXT")
	CreateSharedSwapchainsKHR                              = auto_cast GetInstanceProcAddr(instance, "vkCreateSharedSwapchainsKHR")
	CreateSwapchainKHR                                     = auto_cast GetInstanceProcAddr(instance, "vkCreateSwapchainKHR")
	CreateValidationCacheEXT                               = auto_cast GetInstanceProcAddr(instance, "vkCreateValidationCacheEXT")
	CreateVideoSessionKHR                                  = auto_cast GetInstanceProcAddr(instance, "vkCreateVideoSessionKHR")
	CreateVideoSessionParametersKHR                        = auto_cast GetInstanceProcAddr(instance, "vkCreateVideoSessionParametersKHR")
	DebugMarkerSetObjectNameEXT                            = auto_cast GetInstanceProcAddr(instance, "vkDebugMarkerSetObjectNameEXT")
	DebugMarkerSetObjectTagEXT                             = auto_cast GetInstanceProcAddr(instance, "vkDebugMarkerSetObjectTagEXT")
	DeferredOperationJoinKHR                               = auto_cast GetInstanceProcAddr(instance, "vkDeferredOperationJoinKHR")
	DestroyAccelerationStructureKHR                        = auto_cast GetInstanceProcAddr(instance, "vkDestroyAccelerationStructureKHR")
	DestroyAccelerationStructureNV                         = auto_cast GetInstanceProcAddr(instance, "vkDestroyAccelerationStructureNV")
	DestroyBuffer                                          = auto_cast GetInstanceProcAddr(instance, "vkDestroyBuffer")
	DestroyBufferView                                      = auto_cast GetInstanceProcAddr(instance, "vkDestroyBufferView")
	DestroyCommandPool                                     = auto_cast GetInstanceProcAddr(instance, "vkDestroyCommandPool")
	DestroyCuFunctionNVX                                   = auto_cast GetInstanceProcAddr(instance, "vkDestroyCuFunctionNVX")
	DestroyCuModuleNVX                                     = auto_cast GetInstanceProcAddr(instance, "vkDestroyCuModuleNVX")
	DestroyDeferredOperationKHR                            = auto_cast GetInstanceProcAddr(instance, "vkDestroyDeferredOperationKHR")
	DestroyDescriptorPool                                  = auto_cast GetInstanceProcAddr(instance, "vkDestroyDescriptorPool")
	DestroyDescriptorSetLayout                             = auto_cast GetInstanceProcAddr(instance, "vkDestroyDescriptorSetLayout")
	DestroyDescriptorUpdateTemplate                        = auto_cast GetInstanceProcAddr(instance, "vkDestroyDescriptorUpdateTemplate")
	DestroyDescriptorUpdateTemplateKHR                     = auto_cast GetInstanceProcAddr(instance, "vkDestroyDescriptorUpdateTemplateKHR")
	DestroyDevice                                          = auto_cast GetInstanceProcAddr(instance, "vkDestroyDevice")
	DestroyEvent                                           = auto_cast GetInstanceProcAddr(instance, "vkDestroyEvent")
	DestroyFence                                           = auto_cast GetInstanceProcAddr(instance, "vkDestroyFence")
	DestroyFramebuffer                                     = auto_cast GetInstanceProcAddr(instance, "vkDestroyFramebuffer")
	DestroyImage                                           = auto_cast GetInstanceProcAddr(instance, "vkDestroyImage")
	DestroyImageView                                       = auto_cast GetInstanceProcAddr(instance, "vkDestroyImageView")
	DestroyIndirectCommandsLayoutNV                        = auto_cast GetInstanceProcAddr(instance, "vkDestroyIndirectCommandsLayoutNV")
	DestroyMicromapEXT                                     = auto_cast GetInstanceProcAddr(instance, "vkDestroyMicromapEXT")
	DestroyOpticalFlowSessionNV                            = auto_cast GetInstanceProcAddr(instance, "vkDestroyOpticalFlowSessionNV")
	DestroyPipeline                                        = auto_cast GetInstanceProcAddr(instance, "vkDestroyPipeline")
	DestroyPipelineCache                                   = auto_cast GetInstanceProcAddr(instance, "vkDestroyPipelineCache")
	DestroyPipelineLayout                                  = auto_cast GetInstanceProcAddr(instance, "vkDestroyPipelineLayout")
	DestroyPrivateDataSlot                                 = auto_cast GetInstanceProcAddr(instance, "vkDestroyPrivateDataSlot")
	DestroyPrivateDataSlotEXT                              = auto_cast GetInstanceProcAddr(instance, "vkDestroyPrivateDataSlotEXT")
	DestroyQueryPool                                       = auto_cast GetInstanceProcAddr(instance, "vkDestroyQueryPool")
	DestroyRenderPass                                      = auto_cast GetInstanceProcAddr(instance, "vkDestroyRenderPass")
	DestroySampler                                         = auto_cast GetInstanceProcAddr(instance, "vkDestroySampler")
	DestroySamplerYcbcrConversion                          = auto_cast GetInstanceProcAddr(instance, "vkDestroySamplerYcbcrConversion")
	DestroySamplerYcbcrConversionKHR                       = auto_cast GetInstanceProcAddr(instance, "vkDestroySamplerYcbcrConversionKHR")
	DestroySemaphore                                       = auto_cast GetInstanceProcAddr(instance, "vkDestroySemaphore")
	DestroyShaderEXT                                       = auto_cast GetInstanceProcAddr(instance, "vkDestroyShaderEXT")
	DestroyShaderModule                                    = auto_cast GetInstanceProcAddr(instance, "vkDestroyShaderModule")
	DestroySwapchainKHR                                    = auto_cast GetInstanceProcAddr(instance, "vkDestroySwapchainKHR")
	DestroyValidationCacheEXT                              = auto_cast GetInstanceProcAddr(instance, "vkDestroyValidationCacheEXT")
	DestroyVideoSessionKHR                                 = auto_cast GetInstanceProcAddr(instance, "vkDestroyVideoSessionKHR")
	DestroyVideoSessionParametersKHR                       = auto_cast GetInstanceProcAddr(instance, "vkDestroyVideoSessionParametersKHR")
	DeviceWaitIdle                                         = auto_cast GetInstanceProcAddr(instance, "vkDeviceWaitIdle")
	DisplayPowerControlEXT                                 = auto_cast GetInstanceProcAddr(instance, "vkDisplayPowerControlEXT")
	EndCommandBuffer                                       = auto_cast GetInstanceProcAddr(instance, "vkEndCommandBuffer")
	ExportMetalObjectsEXT                                  = auto_cast GetInstanceProcAddr(instance, "vkExportMetalObjectsEXT")
	FlushMappedMemoryRanges                                = auto_cast GetInstanceProcAddr(instance, "vkFlushMappedMemoryRanges")
	FreeCommandBuffers                                     = auto_cast GetInstanceProcAddr(instance, "vkFreeCommandBuffers")
	FreeDescriptorSets                                     = auto_cast GetInstanceProcAddr(instance, "vkFreeDescriptorSets")
	FreeMemory                                             = auto_cast GetInstanceProcAddr(instance, "vkFreeMemory")
	GetAccelerationStructureBuildSizesKHR                  = auto_cast GetInstanceProcAddr(instance, "vkGetAccelerationStructureBuildSizesKHR")
	GetAccelerationStructureDeviceAddressKHR               = auto_cast GetInstanceProcAddr(instance, "vkGetAccelerationStructureDeviceAddressKHR")
	GetAccelerationStructureHandleNV                       = auto_cast GetInstanceProcAddr(instance, "vkGetAccelerationStructureHandleNV")
	GetAccelerationStructureMemoryRequirementsNV           = auto_cast GetInstanceProcAddr(instance, "vkGetAccelerationStructureMemoryRequirementsNV")
	GetAccelerationStructureOpaqueCaptureDescriptorDataEXT = auto_cast GetInstanceProcAddr(instance, "vkGetAccelerationStructureOpaqueCaptureDescriptorDataEXT")
	GetBufferDeviceAddress                                 = auto_cast GetInstanceProcAddr(instance, "vkGetBufferDeviceAddress")
	GetBufferDeviceAddressEXT                              = auto_cast GetInstanceProcAddr(instance, "vkGetBufferDeviceAddressEXT")
	GetBufferDeviceAddressKHR                              = auto_cast GetInstanceProcAddr(instance, "vkGetBufferDeviceAddressKHR")
	GetBufferMemoryRequirements                            = auto_cast GetInstanceProcAddr(instance, "vkGetBufferMemoryRequirements")
	GetBufferMemoryRequirements2                           = auto_cast GetInstanceProcAddr(instance, "vkGetBufferMemoryRequirements2")
	GetBufferMemoryRequirements2KHR                        = auto_cast GetInstanceProcAddr(instance, "vkGetBufferMemoryRequirements2KHR")
	GetBufferOpaqueCaptureAddress                          = auto_cast GetInstanceProcAddr(instance, "vkGetBufferOpaqueCaptureAddress")
	GetBufferOpaqueCaptureAddressKHR                       = auto_cast GetInstanceProcAddr(instance, "vkGetBufferOpaqueCaptureAddressKHR")
	GetBufferOpaqueCaptureDescriptorDataEXT                = auto_cast GetInstanceProcAddr(instance, "vkGetBufferOpaqueCaptureDescriptorDataEXT")
	GetCalibratedTimestampsEXT                             = auto_cast GetInstanceProcAddr(instance, "vkGetCalibratedTimestampsEXT")
	GetDeferredOperationMaxConcurrencyKHR                  = auto_cast GetInstanceProcAddr(instance, "vkGetDeferredOperationMaxConcurrencyKHR")
	GetDeferredOperationResultKHR                          = auto_cast GetInstanceProcAddr(instance, "vkGetDeferredOperationResultKHR")
	GetDescriptorEXT                                       = auto_cast GetInstanceProcAddr(instance, "vkGetDescriptorEXT")
	GetDescriptorSetHostMappingVALVE                       = auto_cast GetInstanceProcAddr(instance, "vkGetDescriptorSetHostMappingVALVE")
	GetDescriptorSetLayoutBindingOffsetEXT                 = auto_cast GetInstanceProcAddr(instance, "vkGetDescriptorSetLayoutBindingOffsetEXT")
	GetDescriptorSetLayoutHostMappingInfoVALVE             = auto_cast GetInstanceProcAddr(instance, "vkGetDescriptorSetLayoutHostMappingInfoVALVE")
	GetDescriptorSetLayoutSizeEXT                          = auto_cast GetInstanceProcAddr(instance, "vkGetDescriptorSetLayoutSizeEXT")
	GetDescriptorSetLayoutSupport                          = auto_cast GetInstanceProcAddr(instance, "vkGetDescriptorSetLayoutSupport")
	GetDescriptorSetLayoutSupportKHR                       = auto_cast GetInstanceProcAddr(instance, "vkGetDescriptorSetLayoutSupportKHR")
	GetDeviceAccelerationStructureCompatibilityKHR         = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceAccelerationStructureCompatibilityKHR")
	GetDeviceBufferMemoryRequirements                      = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceBufferMemoryRequirements")
	GetDeviceBufferMemoryRequirementsKHR                   = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceBufferMemoryRequirementsKHR")
	GetDeviceFaultInfoEXT                                  = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceFaultInfoEXT")
	GetDeviceGroupPeerMemoryFeatures                       = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceGroupPeerMemoryFeatures")
	GetDeviceGroupPeerMemoryFeaturesKHR                    = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceGroupPeerMemoryFeaturesKHR")
	GetDeviceGroupPresentCapabilitiesKHR                   = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceGroupPresentCapabilitiesKHR")
	GetDeviceGroupSurfacePresentModes2EXT                  = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceGroupSurfacePresentModes2EXT")
	GetDeviceGroupSurfacePresentModesKHR                   = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceGroupSurfacePresentModesKHR")
	GetDeviceImageMemoryRequirements                       = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceImageMemoryRequirements")
	GetDeviceImageMemoryRequirementsKHR                    = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceImageMemoryRequirementsKHR")
	GetDeviceImageSparseMemoryRequirements                 = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceImageSparseMemoryRequirements")
	GetDeviceImageSparseMemoryRequirementsKHR              = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceImageSparseMemoryRequirementsKHR")
	GetDeviceMemoryCommitment                              = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceMemoryCommitment")
	GetDeviceMemoryOpaqueCaptureAddress                    = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceMemoryOpaqueCaptureAddress")
	GetDeviceMemoryOpaqueCaptureAddressKHR                 = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceMemoryOpaqueCaptureAddressKHR")
	GetDeviceMicromapCompatibilityEXT                      = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceMicromapCompatibilityEXT")
	GetDeviceProcAddr                                      = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceProcAddr")
	GetDeviceQueue                                         = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceQueue")
	GetDeviceQueue2                                        = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceQueue2")
	GetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI          = auto_cast GetInstanceProcAddr(instance, "vkGetDeviceSubpassShadingMaxWorkgroupSizeHUAWEI")
	GetDynamicRenderingTilePropertiesQCOM                  = auto_cast GetInstanceProcAddr(instance, "vkGetDynamicRenderingTilePropertiesQCOM")
	GetEventStatus                                         = auto_cast GetInstanceProcAddr(instance, "vkGetEventStatus")
	GetFenceFdKHR                                          = auto_cast GetInstanceProcAddr(instance, "vkGetFenceFdKHR")
	GetFenceStatus                                         = auto_cast GetInstanceProcAddr(instance, "vkGetFenceStatus")
	GetFenceWin32HandleKHR                                 = auto_cast GetInstanceProcAddr(instance, "vkGetFenceWin32HandleKHR")
	GetFramebufferTilePropertiesQCOM                       = auto_cast GetInstanceProcAddr(instance, "vkGetFramebufferTilePropertiesQCOM")
	GetGeneratedCommandsMemoryRequirementsNV               = auto_cast GetInstanceProcAddr(instance, "vkGetGeneratedCommandsMemoryRequirementsNV")
	GetImageDrmFormatModifierPropertiesEXT                 = auto_cast GetInstanceProcAddr(instance, "vkGetImageDrmFormatModifierPropertiesEXT")
	GetImageMemoryRequirements                             = auto_cast GetInstanceProcAddr(instance, "vkGetImageMemoryRequirements")
	GetImageMemoryRequirements2                            = auto_cast GetInstanceProcAddr(instance, "vkGetImageMemoryRequirements2")
	GetImageMemoryRequirements2KHR                         = auto_cast GetInstanceProcAddr(instance, "vkGetImageMemoryRequirements2KHR")
	GetImageOpaqueCaptureDescriptorDataEXT                 = auto_cast GetInstanceProcAddr(instance, "vkGetImageOpaqueCaptureDescriptorDataEXT")
	GetImageSparseMemoryRequirements                       = auto_cast GetInstanceProcAddr(instance, "vkGetImageSparseMemoryRequirements")
	GetImageSparseMemoryRequirements2                      = auto_cast GetInstanceProcAddr(instance, "vkGetImageSparseMemoryRequirements2")
	GetImageSparseMemoryRequirements2KHR                   = auto_cast GetInstanceProcAddr(instance, "vkGetImageSparseMemoryRequirements2KHR")
	GetImageSubresourceLayout                              = auto_cast GetInstanceProcAddr(instance, "vkGetImageSubresourceLayout")
	GetImageSubresourceLayout2EXT                          = auto_cast GetInstanceProcAddr(instance, "vkGetImageSubresourceLayout2EXT")
	GetImageViewAddressNVX                                 = auto_cast GetInstanceProcAddr(instance, "vkGetImageViewAddressNVX")
	GetImageViewHandleNVX                                  = auto_cast GetInstanceProcAddr(instance, "vkGetImageViewHandleNVX")
	GetImageViewOpaqueCaptureDescriptorDataEXT             = auto_cast GetInstanceProcAddr(instance, "vkGetImageViewOpaqueCaptureDescriptorDataEXT")
	GetMemoryFdKHR                                         = auto_cast GetInstanceProcAddr(instance, "vkGetMemoryFdKHR")
	GetMemoryFdPropertiesKHR                               = auto_cast GetInstanceProcAddr(instance, "vkGetMemoryFdPropertiesKHR")
	GetMemoryHostPointerPropertiesEXT                      = auto_cast GetInstanceProcAddr(instance, "vkGetMemoryHostPointerPropertiesEXT")
	GetMemoryRemoteAddressNV                               = auto_cast GetInstanceProcAddr(instance, "vkGetMemoryRemoteAddressNV")
	GetMemoryWin32HandleKHR                                = auto_cast GetInstanceProcAddr(instance, "vkGetMemoryWin32HandleKHR")
	GetMemoryWin32HandleNV                                 = auto_cast GetInstanceProcAddr(instance, "vkGetMemoryWin32HandleNV")
	GetMemoryWin32HandlePropertiesKHR                      = auto_cast GetInstanceProcAddr(instance, "vkGetMemoryWin32HandlePropertiesKHR")
	GetMicromapBuildSizesEXT                               = auto_cast GetInstanceProcAddr(instance, "vkGetMicromapBuildSizesEXT")
	GetPastPresentationTimingGOOGLE                        = auto_cast GetInstanceProcAddr(instance, "vkGetPastPresentationTimingGOOGLE")
	GetPerformanceParameterINTEL                           = auto_cast GetInstanceProcAddr(instance, "vkGetPerformanceParameterINTEL")
	GetPipelineCacheData                                   = auto_cast GetInstanceProcAddr(instance, "vkGetPipelineCacheData")
	GetPipelineExecutableInternalRepresentationsKHR        = auto_cast GetInstanceProcAddr(instance, "vkGetPipelineExecutableInternalRepresentationsKHR")
	GetPipelineExecutablePropertiesKHR                     = auto_cast GetInstanceProcAddr(instance, "vkGetPipelineExecutablePropertiesKHR")
	GetPipelineExecutableStatisticsKHR                     = auto_cast GetInstanceProcAddr(instance, "vkGetPipelineExecutableStatisticsKHR")
	GetPipelinePropertiesEXT                               = auto_cast GetInstanceProcAddr(instance, "vkGetPipelinePropertiesEXT")
	GetPrivateData                                         = auto_cast GetInstanceProcAddr(instance, "vkGetPrivateData")
	GetPrivateDataEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkGetPrivateDataEXT")
	GetQueryPoolResults                                    = auto_cast GetInstanceProcAddr(instance, "vkGetQueryPoolResults")
	GetQueueCheckpointData2NV                              = auto_cast GetInstanceProcAddr(instance, "vkGetQueueCheckpointData2NV")
	GetQueueCheckpointDataNV                               = auto_cast GetInstanceProcAddr(instance, "vkGetQueueCheckpointDataNV")
	GetRayTracingCaptureReplayShaderGroupHandlesKHR        = auto_cast GetInstanceProcAddr(instance, "vkGetRayTracingCaptureReplayShaderGroupHandlesKHR")
	GetRayTracingShaderGroupHandlesKHR                     = auto_cast GetInstanceProcAddr(instance, "vkGetRayTracingShaderGroupHandlesKHR")
	GetRayTracingShaderGroupHandlesNV                      = auto_cast GetInstanceProcAddr(instance, "vkGetRayTracingShaderGroupHandlesNV")
	GetRayTracingShaderGroupStackSizeKHR                   = auto_cast GetInstanceProcAddr(instance, "vkGetRayTracingShaderGroupStackSizeKHR")
	GetRefreshCycleDurationGOOGLE                          = auto_cast GetInstanceProcAddr(instance, "vkGetRefreshCycleDurationGOOGLE")
	GetRenderAreaGranularity                               = auto_cast GetInstanceProcAddr(instance, "vkGetRenderAreaGranularity")
	GetSamplerOpaqueCaptureDescriptorDataEXT               = auto_cast GetInstanceProcAddr(instance, "vkGetSamplerOpaqueCaptureDescriptorDataEXT")
	GetSemaphoreCounterValue                               = auto_cast GetInstanceProcAddr(instance, "vkGetSemaphoreCounterValue")
	GetSemaphoreCounterValueKHR                            = auto_cast GetInstanceProcAddr(instance, "vkGetSemaphoreCounterValueKHR")
	GetSemaphoreFdKHR                                      = auto_cast GetInstanceProcAddr(instance, "vkGetSemaphoreFdKHR")
	GetSemaphoreWin32HandleKHR                             = auto_cast GetInstanceProcAddr(instance, "vkGetSemaphoreWin32HandleKHR")
	GetShaderBinaryDataEXT                                 = auto_cast GetInstanceProcAddr(instance, "vkGetShaderBinaryDataEXT")
	GetShaderInfoAMD                                       = auto_cast GetInstanceProcAddr(instance, "vkGetShaderInfoAMD")
	GetShaderModuleCreateInfoIdentifierEXT                 = auto_cast GetInstanceProcAddr(instance, "vkGetShaderModuleCreateInfoIdentifierEXT")
	GetShaderModuleIdentifierEXT                           = auto_cast GetInstanceProcAddr(instance, "vkGetShaderModuleIdentifierEXT")
	GetSwapchainCounterEXT                                 = auto_cast GetInstanceProcAddr(instance, "vkGetSwapchainCounterEXT")
	GetSwapchainImagesKHR                                  = auto_cast GetInstanceProcAddr(instance, "vkGetSwapchainImagesKHR")
	GetSwapchainStatusKHR                                  = auto_cast GetInstanceProcAddr(instance, "vkGetSwapchainStatusKHR")
	GetValidationCacheDataEXT                              = auto_cast GetInstanceProcAddr(instance, "vkGetValidationCacheDataEXT")
	GetVideoSessionMemoryRequirementsKHR                   = auto_cast GetInstanceProcAddr(instance, "vkGetVideoSessionMemoryRequirementsKHR")
	ImportFenceFdKHR                                       = auto_cast GetInstanceProcAddr(instance, "vkImportFenceFdKHR")
	ImportFenceWin32HandleKHR                              = auto_cast GetInstanceProcAddr(instance, "vkImportFenceWin32HandleKHR")
	ImportSemaphoreFdKHR                                   = auto_cast GetInstanceProcAddr(instance, "vkImportSemaphoreFdKHR")
	ImportSemaphoreWin32HandleKHR                          = auto_cast GetInstanceProcAddr(instance, "vkImportSemaphoreWin32HandleKHR")
	InitializePerformanceApiINTEL                          = auto_cast GetInstanceProcAddr(instance, "vkInitializePerformanceApiINTEL")
	InvalidateMappedMemoryRanges                           = auto_cast GetInstanceProcAddr(instance, "vkInvalidateMappedMemoryRanges")
	MapMemory                                              = auto_cast GetInstanceProcAddr(instance, "vkMapMemory")
	MapMemory2KHR                                          = auto_cast GetInstanceProcAddr(instance, "vkMapMemory2KHR")
	MergePipelineCaches                                    = auto_cast GetInstanceProcAddr(instance, "vkMergePipelineCaches")
	MergeValidationCachesEXT                               = auto_cast GetInstanceProcAddr(instance, "vkMergeValidationCachesEXT")
	QueueBeginDebugUtilsLabelEXT                           = auto_cast GetInstanceProcAddr(instance, "vkQueueBeginDebugUtilsLabelEXT")
	QueueBindSparse                                        = auto_cast GetInstanceProcAddr(instance, "vkQueueBindSparse")
	QueueEndDebugUtilsLabelEXT                             = auto_cast GetInstanceProcAddr(instance, "vkQueueEndDebugUtilsLabelEXT")
	QueueInsertDebugUtilsLabelEXT                          = auto_cast GetInstanceProcAddr(instance, "vkQueueInsertDebugUtilsLabelEXT")
	QueuePresentKHR                                        = auto_cast GetInstanceProcAddr(instance, "vkQueuePresentKHR")
	QueueSetPerformanceConfigurationINTEL                  = auto_cast GetInstanceProcAddr(instance, "vkQueueSetPerformanceConfigurationINTEL")
	QueueSubmit                                            = auto_cast GetInstanceProcAddr(instance, "vkQueueSubmit")
	QueueSubmit2                                           = auto_cast GetInstanceProcAddr(instance, "vkQueueSubmit2")
	QueueSubmit2KHR                                        = auto_cast GetInstanceProcAddr(instance, "vkQueueSubmit2KHR")
	QueueWaitIdle                                          = auto_cast GetInstanceProcAddr(instance, "vkQueueWaitIdle")
	RegisterDeviceEventEXT                                 = auto_cast GetInstanceProcAddr(instance, "vkRegisterDeviceEventEXT")
	RegisterDisplayEventEXT                                = auto_cast GetInstanceProcAddr(instance, "vkRegisterDisplayEventEXT")
	ReleaseFullScreenExclusiveModeEXT                      = auto_cast GetInstanceProcAddr(instance, "vkReleaseFullScreenExclusiveModeEXT")
	ReleasePerformanceConfigurationINTEL                   = auto_cast GetInstanceProcAddr(instance, "vkReleasePerformanceConfigurationINTEL")
	ReleaseProfilingLockKHR                                = auto_cast GetInstanceProcAddr(instance, "vkReleaseProfilingLockKHR")
	ReleaseSwapchainImagesEXT                              = auto_cast GetInstanceProcAddr(instance, "vkReleaseSwapchainImagesEXT")
	ResetCommandBuffer                                     = auto_cast GetInstanceProcAddr(instance, "vkResetCommandBuffer")
	ResetCommandPool                                       = auto_cast GetInstanceProcAddr(instance, "vkResetCommandPool")
	ResetDescriptorPool                                    = auto_cast GetInstanceProcAddr(instance, "vkResetDescriptorPool")
	ResetEvent                                             = auto_cast GetInstanceProcAddr(instance, "vkResetEvent")
	ResetFences                                            = auto_cast GetInstanceProcAddr(instance, "vkResetFences")
	ResetQueryPool                                         = auto_cast GetInstanceProcAddr(instance, "vkResetQueryPool")
	ResetQueryPoolEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkResetQueryPoolEXT")
	SetDebugUtilsObjectNameEXT                             = auto_cast GetInstanceProcAddr(instance, "vkSetDebugUtilsObjectNameEXT")
	SetDebugUtilsObjectTagEXT                              = auto_cast GetInstanceProcAddr(instance, "vkSetDebugUtilsObjectTagEXT")
	SetDeviceMemoryPriorityEXT                             = auto_cast GetInstanceProcAddr(instance, "vkSetDeviceMemoryPriorityEXT")
	SetEvent                                               = auto_cast GetInstanceProcAddr(instance, "vkSetEvent")
	SetHdrMetadataEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkSetHdrMetadataEXT")
	SetLocalDimmingAMD                                     = auto_cast GetInstanceProcAddr(instance, "vkSetLocalDimmingAMD")
	SetPrivateData                                         = auto_cast GetInstanceProcAddr(instance, "vkSetPrivateData")
	SetPrivateDataEXT                                      = auto_cast GetInstanceProcAddr(instance, "vkSetPrivateDataEXT")
	SignalSemaphore                                        = auto_cast GetInstanceProcAddr(instance, "vkSignalSemaphore")
	SignalSemaphoreKHR                                     = auto_cast GetInstanceProcAddr(instance, "vkSignalSemaphoreKHR")
	TrimCommandPool                                        = auto_cast GetInstanceProcAddr(instance, "vkTrimCommandPool")
	TrimCommandPoolKHR                                     = auto_cast GetInstanceProcAddr(instance, "vkTrimCommandPoolKHR")
	UninitializePerformanceApiINTEL                        = auto_cast GetInstanceProcAddr(instance, "vkUninitializePerformanceApiINTEL")
	UnmapMemory                                            = auto_cast GetInstanceProcAddr(instance, "vkUnmapMemory")
	UnmapMemory2KHR                                        = auto_cast GetInstanceProcAddr(instance, "vkUnmapMemory2KHR")
	UpdateDescriptorSetWithTemplate                        = auto_cast GetInstanceProcAddr(instance, "vkUpdateDescriptorSetWithTemplate")
	UpdateDescriptorSetWithTemplateKHR                     = auto_cast GetInstanceProcAddr(instance, "vkUpdateDescriptorSetWithTemplateKHR")
	UpdateDescriptorSets                                   = auto_cast GetInstanceProcAddr(instance, "vkUpdateDescriptorSets")
	UpdateVideoSessionParametersKHR                        = auto_cast GetInstanceProcAddr(instance, "vkUpdateVideoSessionParametersKHR")
	WaitForFences                                          = auto_cast GetInstanceProcAddr(instance, "vkWaitForFences")
	WaitForPresentKHR                                      = auto_cast GetInstanceProcAddr(instance, "vkWaitForPresentKHR")
	WaitSemaphores                                         = auto_cast GetInstanceProcAddr(instance, "vkWaitSemaphores")
	WaitSemaphoresKHR                                      = auto_cast GetInstanceProcAddr(instance, "vkWaitSemaphoresKHR")
	WriteAccelerationStructuresPropertiesKHR               = auto_cast GetInstanceProcAddr(instance, "vkWriteAccelerationStructuresPropertiesKHR")
	WriteMicromapsPropertiesEXT                            = auto_cast GetInstanceProcAddr(instance, "vkWriteMicromapsPropertiesEXT")
}

load_proc_addresses_global :: proc(vk_get_instance_proc_addr: rawptr) {
	GetInstanceProcAddr = auto_cast vk_get_instance_proc_addr

	CreateInstance                       = auto_cast GetInstanceProcAddr(nil, "vkCreateInstance")
	DebugUtilsMessengerCallbackEXT       = auto_cast GetInstanceProcAddr(nil, "vkDebugUtilsMessengerCallbackEXT")
	DeviceMemoryReportCallbackEXT        = auto_cast GetInstanceProcAddr(nil, "vkDeviceMemoryReportCallbackEXT")
	EnumerateInstanceExtensionProperties = auto_cast GetInstanceProcAddr(nil, "vkEnumerateInstanceExtensionProperties")
	EnumerateInstanceLayerProperties     = auto_cast GetInstanceProcAddr(nil, "vkEnumerateInstanceLayerProperties")
	EnumerateInstanceVersion             = auto_cast GetInstanceProcAddr(nil, "vkEnumerateInstanceVersion")
	GetInstanceProcAddr                  = auto_cast GetInstanceProcAddr(nil, "vkGetInstanceProcAddr")
}

load_proc_addresses :: proc{
	load_proc_addresses_global,
	load_proc_addresses_instance,
	load_proc_addresses_device,
	load_proc_addresses_device_vtable,
	load_proc_addresses_custom,
}

