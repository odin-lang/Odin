//
// Vulkan wrapper generated from "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Headers/master/include/vulkan/vulkan_core.h"
//
package vulkan

import "core:c"

// Enums
AccelerationStructureBuildTypeKHR :: enum c.int {
	HOST           = 0,
	DEVICE         = 1,
	HOST_OR_DEVICE = 2,
}

AccelerationStructureCompatibilityKHR :: enum c.int {
	COMPATIBLE   = 0,
	INCOMPATIBLE = 1,
}

AccelerationStructureCreateFlagsKHR :: distinct bit_set[AccelerationStructureCreateFlagKHR; Flags]
AccelerationStructureCreateFlagKHR :: enum Flags {
	DEVICE_ADDRESS_CAPTURE_REPLAY = 0,
	MOTION_NV                     = 2,
}

AccelerationStructureMemoryRequirementsTypeNV :: enum c.int {
	OBJECT         = 0,
	BUILD_SCRATCH  = 1,
	UPDATE_SCRATCH = 2,
}

AccelerationStructureMotionInstanceTypeNV :: enum c.int {
	STATIC        = 0,
	MATRIX_MOTION = 1,
	SRT_MOTION    = 2,
}

AccelerationStructureTypeKHR :: enum c.int {
	TOP_LEVEL       = 0,
	BOTTOM_LEVEL    = 1,
	GENERIC         = 2,
	TOP_LEVEL_NV    = TOP_LEVEL,
	BOTTOM_LEVEL_NV = BOTTOM_LEVEL,
}

AccessFlags :: distinct bit_set[AccessFlag; Flags]
AccessFlag :: enum Flags {
	INDIRECT_COMMAND_READ                     = 0,
	INDEX_READ                                = 1,
	VERTEX_ATTRIBUTE_READ                     = 2,
	UNIFORM_READ                              = 3,
	INPUT_ATTACHMENT_READ                     = 4,
	SHADER_READ                               = 5,
	SHADER_WRITE                              = 6,
	COLOR_ATTACHMENT_READ                     = 7,
	COLOR_ATTACHMENT_WRITE                    = 8,
	DEPTH_STENCIL_ATTACHMENT_READ             = 9,
	DEPTH_STENCIL_ATTACHMENT_WRITE            = 10,
	TRANSFER_READ                             = 11,
	TRANSFER_WRITE                            = 12,
	HOST_READ                                 = 13,
	HOST_WRITE                                = 14,
	MEMORY_READ                               = 15,
	MEMORY_WRITE                              = 16,
	TRANSFORM_FEEDBACK_WRITE_EXT              = 25,
	TRANSFORM_FEEDBACK_COUNTER_READ_EXT       = 26,
	TRANSFORM_FEEDBACK_COUNTER_WRITE_EXT      = 27,
	CONDITIONAL_RENDERING_READ_EXT            = 20,
	COLOR_ATTACHMENT_READ_NONCOHERENT_EXT     = 19,
	ACCELERATION_STRUCTURE_READ_KHR           = 21,
	ACCELERATION_STRUCTURE_WRITE_KHR          = 22,
	FRAGMENT_DENSITY_MAP_READ_EXT             = 24,
	FRAGMENT_SHADING_RATE_ATTACHMENT_READ_KHR = 23,
	COMMAND_PREPROCESS_READ_NV                = 17,
	COMMAND_PREPROCESS_WRITE_NV               = 18,
	SHADING_RATE_IMAGE_READ_NV                = FRAGMENT_SHADING_RATE_ATTACHMENT_READ_KHR,
	ACCELERATION_STRUCTURE_READ_NV            = ACCELERATION_STRUCTURE_READ_KHR,
	ACCELERATION_STRUCTURE_WRITE_NV           = ACCELERATION_STRUCTURE_WRITE_KHR,
}

AccessFlags_NONE :: AccessFlags{}


AcquireProfilingLockFlagsKHR :: distinct bit_set[AcquireProfilingLockFlagKHR; Flags]
AcquireProfilingLockFlagKHR :: enum Flags {
}

AttachmentDescriptionFlags :: distinct bit_set[AttachmentDescriptionFlag; Flags]
AttachmentDescriptionFlag :: enum Flags {
	MAY_ALIAS = 0,
}

AttachmentLoadOp :: enum c.int {
	LOAD      = 0,
	CLEAR     = 1,
	DONT_CARE = 2,
	NONE_EXT  = 1000400000,
}

AttachmentStoreOp :: enum c.int {
	STORE     = 0,
	DONT_CARE = 1,
	NONE      = 1000301000,
}

BlendFactor :: enum c.int {
	ZERO                     = 0,
	ONE                      = 1,
	SRC_COLOR                = 2,
	ONE_MINUS_SRC_COLOR      = 3,
	DST_COLOR                = 4,
	ONE_MINUS_DST_COLOR      = 5,
	SRC_ALPHA                = 6,
	ONE_MINUS_SRC_ALPHA      = 7,
	DST_ALPHA                = 8,
	ONE_MINUS_DST_ALPHA      = 9,
	CONSTANT_COLOR           = 10,
	ONE_MINUS_CONSTANT_COLOR = 11,
	CONSTANT_ALPHA           = 12,
	ONE_MINUS_CONSTANT_ALPHA = 13,
	SRC_ALPHA_SATURATE       = 14,
	SRC1_COLOR               = 15,
	ONE_MINUS_SRC1_COLOR     = 16,
	SRC1_ALPHA               = 17,
	ONE_MINUS_SRC1_ALPHA     = 18,
}

BlendOp :: enum c.int {
	ADD                    = 0,
	SUBTRACT               = 1,
	REVERSE_SUBTRACT       = 2,
	MIN                    = 3,
	MAX                    = 4,
	ZERO_EXT               = 1000148000,
	SRC_EXT                = 1000148001,
	DST_EXT                = 1000148002,
	SRC_OVER_EXT           = 1000148003,
	DST_OVER_EXT           = 1000148004,
	SRC_IN_EXT             = 1000148005,
	DST_IN_EXT             = 1000148006,
	SRC_OUT_EXT            = 1000148007,
	DST_OUT_EXT            = 1000148008,
	SRC_ATOP_EXT           = 1000148009,
	DST_ATOP_EXT           = 1000148010,
	XOR_EXT                = 1000148011,
	MULTIPLY_EXT           = 1000148012,
	SCREEN_EXT             = 1000148013,
	OVERLAY_EXT            = 1000148014,
	DARKEN_EXT             = 1000148015,
	LIGHTEN_EXT            = 1000148016,
	COLORDODGE_EXT         = 1000148017,
	COLORBURN_EXT          = 1000148018,
	HARDLIGHT_EXT          = 1000148019,
	SOFTLIGHT_EXT          = 1000148020,
	DIFFERENCE_EXT         = 1000148021,
	EXCLUSION_EXT          = 1000148022,
	INVERT_EXT             = 1000148023,
	INVERT_RGB_EXT         = 1000148024,
	LINEARDODGE_EXT        = 1000148025,
	LINEARBURN_EXT         = 1000148026,
	VIVIDLIGHT_EXT         = 1000148027,
	LINEARLIGHT_EXT        = 1000148028,
	PINLIGHT_EXT           = 1000148029,
	HARDMIX_EXT            = 1000148030,
	HSL_HUE_EXT            = 1000148031,
	HSL_SATURATION_EXT     = 1000148032,
	HSL_COLOR_EXT          = 1000148033,
	HSL_LUMINOSITY_EXT     = 1000148034,
	PLUS_EXT               = 1000148035,
	PLUS_CLAMPED_EXT       = 1000148036,
	PLUS_CLAMPED_ALPHA_EXT = 1000148037,
	PLUS_DARKER_EXT        = 1000148038,
	MINUS_EXT              = 1000148039,
	MINUS_CLAMPED_EXT      = 1000148040,
	CONTRAST_EXT           = 1000148041,
	INVERT_OVG_EXT         = 1000148042,
	RED_EXT                = 1000148043,
	GREEN_EXT              = 1000148044,
	BLUE_EXT               = 1000148045,
}

BlendOverlapEXT :: enum c.int {
	UNCORRELATED = 0,
	DISJOINT     = 1,
	CONJOINT     = 2,
}

BorderColor :: enum c.int {
	FLOAT_TRANSPARENT_BLACK = 0,
	INT_TRANSPARENT_BLACK   = 1,
	FLOAT_OPAQUE_BLACK      = 2,
	INT_OPAQUE_BLACK        = 3,
	FLOAT_OPAQUE_WHITE      = 4,
	INT_OPAQUE_WHITE        = 5,
	FLOAT_CUSTOM_EXT        = 1000287003,
	INT_CUSTOM_EXT          = 1000287004,
}

BufferCreateFlags :: distinct bit_set[BufferCreateFlag; Flags]
BufferCreateFlag :: enum Flags {
	SPARSE_BINDING                    = 0,
	SPARSE_RESIDENCY                  = 1,
	SPARSE_ALIASED                    = 2,
	PROTECTED                         = 3,
	DEVICE_ADDRESS_CAPTURE_REPLAY     = 4,
	DEVICE_ADDRESS_CAPTURE_REPLAY_EXT = DEVICE_ADDRESS_CAPTURE_REPLAY,
	DEVICE_ADDRESS_CAPTURE_REPLAY_KHR = DEVICE_ADDRESS_CAPTURE_REPLAY,
}

BufferUsageFlags :: distinct bit_set[BufferUsageFlag; Flags]
BufferUsageFlag :: enum Flags {
	TRANSFER_SRC                                     = 0,
	TRANSFER_DST                                     = 1,
	UNIFORM_TEXEL_BUFFER                             = 2,
	STORAGE_TEXEL_BUFFER                             = 3,
	UNIFORM_BUFFER                                   = 4,
	STORAGE_BUFFER                                   = 5,
	INDEX_BUFFER                                     = 6,
	VERTEX_BUFFER                                    = 7,
	INDIRECT_BUFFER                                  = 8,
	SHADER_DEVICE_ADDRESS                            = 17,
	VIDEO_DECODE_SRC_KHR                             = 13,
	VIDEO_DECODE_DST_KHR                             = 14,
	TRANSFORM_FEEDBACK_BUFFER_EXT                    = 11,
	TRANSFORM_FEEDBACK_COUNTER_BUFFER_EXT            = 12,
	CONDITIONAL_RENDERING_EXT                        = 9,
	ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY_KHR = 19,
	ACCELERATION_STRUCTURE_STORAGE_KHR               = 20,
	SHADER_BINDING_TABLE_KHR                         = 10,
	VIDEO_ENCODE_DST_KHR                             = 15,
	VIDEO_ENCODE_SRC_KHR                             = 16,
	RAY_TRACING_NV                                   = SHADER_BINDING_TABLE_KHR,
	SHADER_DEVICE_ADDRESS_EXT                        = SHADER_DEVICE_ADDRESS,
	SHADER_DEVICE_ADDRESS_KHR                        = SHADER_DEVICE_ADDRESS,
}

BuildAccelerationStructureFlagsKHR :: distinct bit_set[BuildAccelerationStructureFlagKHR; Flags]
BuildAccelerationStructureFlagKHR :: enum Flags {
	ALLOW_UPDATE         = 0,
	ALLOW_COMPACTION     = 1,
	PREFER_FAST_TRACE    = 2,
	PREFER_FAST_BUILD    = 3,
	LOW_MEMORY           = 4,
	MOTION_NV            = 5,
	ALLOW_UPDATE_NV      = ALLOW_UPDATE,
	ALLOW_COMPACTION_NV  = ALLOW_COMPACTION,
	PREFER_FAST_TRACE_NV = PREFER_FAST_TRACE,
	PREFER_FAST_BUILD_NV = PREFER_FAST_BUILD,
	LOW_MEMORY_NV        = LOW_MEMORY,
}

BuildAccelerationStructureModeKHR :: enum c.int {
	BUILD  = 0,
	UPDATE = 1,
}

ChromaLocation :: enum c.int {
	COSITED_EVEN     = 0,
	MIDPOINT         = 1,
	COSITED_EVEN_KHR = COSITED_EVEN,
	MIDPOINT_KHR     = MIDPOINT,
}

CoarseSampleOrderTypeNV :: enum c.int {
	DEFAULT      = 0,
	CUSTOM       = 1,
	PIXEL_MAJOR  = 2,
	SAMPLE_MAJOR = 3,
}

ColorComponentFlags :: distinct bit_set[ColorComponentFlag; Flags]
ColorComponentFlag :: enum Flags {
	R = 0,
	G = 1,
	B = 2,
	A = 3,
}

ColorSpaceKHR :: enum c.int {
	SRGB_NONLINEAR              = 0,
	DISPLAY_P3_NONLINEAR_EXT    = 1000104001,
	EXTENDED_SRGB_LINEAR_EXT    = 1000104002,
	DISPLAY_P3_LINEAR_EXT       = 1000104003,
	DCI_P3_NONLINEAR_EXT        = 1000104004,
	BT709_LINEAR_EXT            = 1000104005,
	BT709_NONLINEAR_EXT         = 1000104006,
	BT2020_LINEAR_EXT           = 1000104007,
	HDR10_ST2084_EXT            = 1000104008,
	DOLBYVISION_EXT             = 1000104009,
	HDR10_HLG_EXT               = 1000104010,
	ADOBERGB_LINEAR_EXT         = 1000104011,
	ADOBERGB_NONLINEAR_EXT      = 1000104012,
	PASS_THROUGH_EXT            = 1000104013,
	EXTENDED_SRGB_NONLINEAR_EXT = 1000104014,
	DISPLAY_NATIVE_AMD          = 1000213000,
	COLORSPACE_SRGB_NONLINEAR   = SRGB_NONLINEAR,
	DCI_P3_LINEAR_EXT           = DISPLAY_P3_LINEAR_EXT,
}

CommandBufferLevel :: enum c.int {
	PRIMARY   = 0,
	SECONDARY = 1,
}

CommandBufferResetFlags :: distinct bit_set[CommandBufferResetFlag; Flags]
CommandBufferResetFlag :: enum Flags {
	RELEASE_RESOURCES = 0,
}

CommandBufferUsageFlags :: distinct bit_set[CommandBufferUsageFlag; Flags]
CommandBufferUsageFlag :: enum Flags {
	ONE_TIME_SUBMIT      = 0,
	RENDER_PASS_CONTINUE = 1,
	SIMULTANEOUS_USE     = 2,
}

CommandPoolCreateFlags :: distinct bit_set[CommandPoolCreateFlag; Flags]
CommandPoolCreateFlag :: enum Flags {
	TRANSIENT            = 0,
	RESET_COMMAND_BUFFER = 1,
	PROTECTED            = 2,
}

CommandPoolResetFlags :: distinct bit_set[CommandPoolResetFlag; Flags]
CommandPoolResetFlag :: enum Flags {
	RELEASE_RESOURCES = 0,
}

CompareOp :: enum c.int {
	NEVER            = 0,
	LESS             = 1,
	EQUAL            = 2,
	LESS_OR_EQUAL    = 3,
	GREATER          = 4,
	NOT_EQUAL        = 5,
	GREATER_OR_EQUAL = 6,
	ALWAYS           = 7,
}

ComponentSwizzle :: enum c.int {
	IDENTITY = 0,
	ZERO     = 1,
	ONE      = 2,
	R        = 3,
	G        = 4,
	B        = 5,
	A        = 6,
}

ComponentTypeNV :: enum c.int {
	FLOAT16 = 0,
	FLOAT32 = 1,
	FLOAT64 = 2,
	SINT8   = 3,
	SINT16  = 4,
	SINT32  = 5,
	SINT64  = 6,
	UINT8   = 7,
	UINT16  = 8,
	UINT32  = 9,
	UINT64  = 10,
}

CompositeAlphaFlagsKHR :: distinct bit_set[CompositeAlphaFlagKHR; Flags]
CompositeAlphaFlagKHR :: enum Flags {
	OPAQUE          = 0,
	PRE_MULTIPLIED  = 1,
	POST_MULTIPLIED = 2,
	INHERIT         = 3,
}

ConditionalRenderingFlagsEXT :: distinct bit_set[ConditionalRenderingFlagEXT; Flags]
ConditionalRenderingFlagEXT :: enum Flags {
	INVERTED = 0,
}

ConservativeRasterizationModeEXT :: enum c.int {
	DISABLED      = 0,
	OVERESTIMATE  = 1,
	UNDERESTIMATE = 2,
}

CopyAccelerationStructureModeKHR :: enum c.int {
	CLONE       = 0,
	COMPACT     = 1,
	SERIALIZE   = 2,
	DESERIALIZE = 3,
	CLONE_NV    = CLONE,
	COMPACT_NV  = COMPACT,
}

CoverageModulationModeNV :: enum c.int {
	NONE  = 0,
	RGB   = 1,
	ALPHA = 2,
	RGBA  = 3,
}

CoverageReductionModeNV :: enum c.int {
	MERGE    = 0,
	TRUNCATE = 1,
}

CullModeFlags :: distinct bit_set[CullModeFlag; Flags]
CullModeFlag :: enum Flags {
	FRONT = 0,
	BACK  = 1,
}

CullModeFlags_NONE :: CullModeFlags{}
CullModeFlags_FRONT_AND_BACK :: CullModeFlags{.FRONT, .BACK}


DebugReportFlagsEXT :: distinct bit_set[DebugReportFlagEXT; Flags]
DebugReportFlagEXT :: enum Flags {
	INFORMATION         = 0,
	WARNING             = 1,
	PERFORMANCE_WARNING = 2,
	ERROR               = 3,
	DEBUG               = 4,
}

DebugReportObjectTypeEXT :: enum c.int {
	UNKNOWN                        = 0,
	INSTANCE                       = 1,
	PHYSICAL_DEVICE                = 2,
	DEVICE                         = 3,
	QUEUE                          = 4,
	SEMAPHORE                      = 5,
	COMMAND_BUFFER                 = 6,
	FENCE                          = 7,
	DEVICE_MEMORY                  = 8,
	BUFFER                         = 9,
	IMAGE                          = 10,
	EVENT                          = 11,
	QUERY_POOL                     = 12,
	BUFFER_VIEW                    = 13,
	IMAGE_VIEW                     = 14,
	SHADER_MODULE                  = 15,
	PIPELINE_CACHE                 = 16,
	PIPELINE_LAYOUT                = 17,
	RENDER_PASS                    = 18,
	PIPELINE                       = 19,
	DESCRIPTOR_SET_LAYOUT          = 20,
	SAMPLER                        = 21,
	DESCRIPTOR_POOL                = 22,
	DESCRIPTOR_SET                 = 23,
	FRAMEBUFFER                    = 24,
	COMMAND_POOL                   = 25,
	SURFACE_KHR                    = 26,
	SWAPCHAIN_KHR                  = 27,
	DEBUG_REPORT_CALLBACK_EXT      = 28,
	DISPLAY_KHR                    = 29,
	DISPLAY_MODE_KHR               = 30,
	VALIDATION_CACHE_EXT           = 33,
	SAMPLER_YCBCR_CONVERSION       = 1000156000,
	DESCRIPTOR_UPDATE_TEMPLATE     = 1000085000,
	CU_MODULE_NVX                  = 1000029000,
	CU_FUNCTION_NVX                = 1000029001,
	ACCELERATION_STRUCTURE_KHR     = 1000150000,
	ACCELERATION_STRUCTURE_NV      = 1000165000,
	BUFFER_COLLECTION_FUCHSIA      = 1000366000,
	DEBUG_REPORT                   = DEBUG_REPORT_CALLBACK_EXT,
	VALIDATION_CACHE               = VALIDATION_CACHE_EXT,
	DESCRIPTOR_UPDATE_TEMPLATE_KHR = DESCRIPTOR_UPDATE_TEMPLATE,
	SAMPLER_YCBCR_CONVERSION_KHR   = SAMPLER_YCBCR_CONVERSION,
}

DebugUtilsMessageSeverityFlagsEXT :: distinct bit_set[DebugUtilsMessageSeverityFlagEXT; Flags]
DebugUtilsMessageSeverityFlagEXT :: enum Flags {
	VERBOSE = 0,
	INFO    = 4,
	WARNING = 8,
	ERROR   = 12,
}

DebugUtilsMessageTypeFlagsEXT :: distinct bit_set[DebugUtilsMessageTypeFlagEXT; Flags]
DebugUtilsMessageTypeFlagEXT :: enum Flags {
	GENERAL     = 0,
	VALIDATION  = 1,
	PERFORMANCE = 2,
}

DependencyFlags :: distinct bit_set[DependencyFlag; Flags]
DependencyFlag :: enum Flags {
	BY_REGION        = 0,
	DEVICE_GROUP     = 2,
	VIEW_LOCAL       = 1,
	VIEW_LOCAL_KHR   = VIEW_LOCAL,
	DEVICE_GROUP_KHR = DEVICE_GROUP,
}

DescriptorBindingFlags :: distinct bit_set[DescriptorBindingFlag; Flags]
DescriptorBindingFlag :: enum Flags {
	UPDATE_AFTER_BIND               = 0,
	UPDATE_UNUSED_WHILE_PENDING     = 1,
	PARTIALLY_BOUND                 = 2,
	VARIABLE_DESCRIPTOR_COUNT       = 3,
	UPDATE_AFTER_BIND_EXT           = UPDATE_AFTER_BIND,
	UPDATE_UNUSED_WHILE_PENDING_EXT = UPDATE_UNUSED_WHILE_PENDING,
	PARTIALLY_BOUND_EXT             = PARTIALLY_BOUND,
	VARIABLE_DESCRIPTOR_COUNT_EXT   = VARIABLE_DESCRIPTOR_COUNT,
}

DescriptorPoolCreateFlags :: distinct bit_set[DescriptorPoolCreateFlag; Flags]
DescriptorPoolCreateFlag :: enum Flags {
	FREE_DESCRIPTOR_SET   = 0,
	UPDATE_AFTER_BIND     = 1,
	HOST_ONLY_VALVE       = 2,
	UPDATE_AFTER_BIND_EXT = UPDATE_AFTER_BIND,
}

DescriptorSetLayoutCreateFlags :: distinct bit_set[DescriptorSetLayoutCreateFlag; Flags]
DescriptorSetLayoutCreateFlag :: enum Flags {
	UPDATE_AFTER_BIND_POOL     = 1,
	PUSH_DESCRIPTOR_KHR        = 0,
	HOST_ONLY_POOL_VALVE       = 2,
	UPDATE_AFTER_BIND_POOL_EXT = UPDATE_AFTER_BIND_POOL,
}

DescriptorType :: enum c.int {
	SAMPLER                    = 0,
	COMBINED_IMAGE_SAMPLER     = 1,
	SAMPLED_IMAGE              = 2,
	STORAGE_IMAGE              = 3,
	UNIFORM_TEXEL_BUFFER       = 4,
	STORAGE_TEXEL_BUFFER       = 5,
	UNIFORM_BUFFER             = 6,
	STORAGE_BUFFER             = 7,
	UNIFORM_BUFFER_DYNAMIC     = 8,
	STORAGE_BUFFER_DYNAMIC     = 9,
	INPUT_ATTACHMENT           = 10,
	INLINE_UNIFORM_BLOCK       = 1000138000,
	ACCELERATION_STRUCTURE_KHR = 1000150000,
	ACCELERATION_STRUCTURE_NV  = 1000165000,
	MUTABLE_VALVE              = 1000351000,
	INLINE_UNIFORM_BLOCK_EXT   = INLINE_UNIFORM_BLOCK,
}

DescriptorUpdateTemplateType :: enum c.int {
	DESCRIPTOR_SET       = 0,
	PUSH_DESCRIPTORS_KHR = 1,
	DESCRIPTOR_SET_KHR   = DESCRIPTOR_SET,
}

DeviceDiagnosticsConfigFlagsNV :: distinct bit_set[DeviceDiagnosticsConfigFlagNV; Flags]
DeviceDiagnosticsConfigFlagNV :: enum Flags {
	ENABLE_SHADER_DEBUG_INFO     = 0,
	ENABLE_RESOURCE_TRACKING     = 1,
	ENABLE_AUTOMATIC_CHECKPOINTS = 2,
}

DeviceEventTypeEXT :: enum c.int {
	DISPLAY_HOTPLUG = 0,
}

DeviceGroupPresentModeFlagsKHR :: distinct bit_set[DeviceGroupPresentModeFlagKHR; Flags]
DeviceGroupPresentModeFlagKHR :: enum Flags {
	LOCAL              = 0,
	REMOTE             = 1,
	SUM                = 2,
	LOCAL_MULTI_DEVICE = 3,
}

DeviceMemoryReportEventTypeEXT :: enum c.int {
	ALLOCATE          = 0,
	FREE              = 1,
	IMPORT            = 2,
	UNIMPORT          = 3,
	ALLOCATION_FAILED = 4,
}

DeviceQueueCreateFlags :: distinct bit_set[DeviceQueueCreateFlag; Flags]
DeviceQueueCreateFlag :: enum Flags {
	PROTECTED = 0,
}

DiscardRectangleModeEXT :: enum c.int {
	INCLUSIVE = 0,
	EXCLUSIVE = 1,
}

DisplayEventTypeEXT :: enum c.int {
	FIRST_PIXEL_OUT = 0,
}

DisplayPlaneAlphaFlagsKHR :: distinct bit_set[DisplayPlaneAlphaFlagKHR; Flags]
DisplayPlaneAlphaFlagKHR :: enum Flags {
	OPAQUE                  = 0,
	GLOBAL                  = 1,
	PER_PIXEL               = 2,
	PER_PIXEL_PREMULTIPLIED = 3,
}

DisplayPowerStateEXT :: enum c.int {
	OFF     = 0,
	SUSPEND = 1,
	ON      = 2,
}

DriverId :: enum c.int {
	AMD_PROPRIETARY               = 1,
	AMD_OPEN_SOURCE               = 2,
	MESA_RADV                     = 3,
	NVIDIA_PROPRIETARY            = 4,
	INTEL_PROPRIETARY_WINDOWS     = 5,
	INTEL_OPEN_SOURCE_MESA        = 6,
	IMAGINATION_PROPRIETARY       = 7,
	QUALCOMM_PROPRIETARY          = 8,
	ARM_PROPRIETARY               = 9,
	GOOGLE_SWIFTSHADER            = 10,
	GGP_PROPRIETARY               = 11,
	BROADCOM_PROPRIETARY          = 12,
	MESA_LLVMPIPE                 = 13,
	MOLTENVK                      = 14,
	COREAVI_PROPRIETARY           = 15,
	JUICE_PROPRIETARY             = 16,
	VERISILICON_PROPRIETARY       = 17,
	MESA_TURNIP                   = 18,
	MESA_V3DV                     = 19,
	MESA_PANVK                    = 20,
	SAMSUNG_PROPRIETARY           = 21,
	MESA_VENUS                    = 22,
	AMD_PROPRIETARY_KHR           = AMD_PROPRIETARY,
	AMD_OPEN_SOURCE_KHR           = AMD_OPEN_SOURCE,
	MESA_RADV_KHR                 = MESA_RADV,
	NVIDIA_PROPRIETARY_KHR        = NVIDIA_PROPRIETARY,
	INTEL_PROPRIETARY_WINDOWS_KHR = INTEL_PROPRIETARY_WINDOWS,
	INTEL_OPEN_SOURCE_MESA_KHR    = INTEL_OPEN_SOURCE_MESA,
	IMAGINATION_PROPRIETARY_KHR   = IMAGINATION_PROPRIETARY,
	QUALCOMM_PROPRIETARY_KHR      = QUALCOMM_PROPRIETARY,
	ARM_PROPRIETARY_KHR           = ARM_PROPRIETARY,
	GOOGLE_SWIFTSHADER_KHR        = GOOGLE_SWIFTSHADER,
	GGP_PROPRIETARY_KHR           = GGP_PROPRIETARY,
	BROADCOM_PROPRIETARY_KHR      = BROADCOM_PROPRIETARY,
}

DynamicState :: enum c.int {
	VIEWPORT                            = 0,
	SCISSOR                             = 1,
	LINE_WIDTH                          = 2,
	DEPTH_BIAS                          = 3,
	BLEND_CONSTANTS                     = 4,
	DEPTH_BOUNDS                        = 5,
	STENCIL_COMPARE_MASK                = 6,
	STENCIL_WRITE_MASK                  = 7,
	STENCIL_REFERENCE                   = 8,
	CULL_MODE                           = 1000267000,
	FRONT_FACE                          = 1000267001,
	PRIMITIVE_TOPOLOGY                  = 1000267002,
	VIEWPORT_WITH_COUNT                 = 1000267003,
	SCISSOR_WITH_COUNT                  = 1000267004,
	VERTEX_INPUT_BINDING_STRIDE         = 1000267005,
	DEPTH_TEST_ENABLE                   = 1000267006,
	DEPTH_WRITE_ENABLE                  = 1000267007,
	DEPTH_COMPARE_OP                    = 1000267008,
	DEPTH_BOUNDS_TEST_ENABLE            = 1000267009,
	STENCIL_TEST_ENABLE                 = 1000267010,
	STENCIL_OP                          = 1000267011,
	RASTERIZER_DISCARD_ENABLE           = 1000377001,
	DEPTH_BIAS_ENABLE                   = 1000377002,
	PRIMITIVE_RESTART_ENABLE            = 1000377004,
	VIEWPORT_W_SCALING_NV               = 1000087000,
	DISCARD_RECTANGLE_EXT               = 1000099000,
	SAMPLE_LOCATIONS_EXT                = 1000143000,
	RAY_TRACING_PIPELINE_STACK_SIZE_KHR = 1000347000,
	VIEWPORT_SHADING_RATE_PALETTE_NV    = 1000164004,
	VIEWPORT_COARSE_SAMPLE_ORDER_NV     = 1000164006,
	EXCLUSIVE_SCISSOR_NV                = 1000205001,
	FRAGMENT_SHADING_RATE_KHR           = 1000226000,
	LINE_STIPPLE_EXT                    = 1000259000,
	VERTEX_INPUT_EXT                    = 1000352000,
	PATCH_CONTROL_POINTS_EXT            = 1000377000,
	LOGIC_OP_EXT                        = 1000377003,
	COLOR_WRITE_ENABLE_EXT              = 1000381000,
	CULL_MODE_EXT                       = CULL_MODE,
	FRONT_FACE_EXT                      = FRONT_FACE,
	PRIMITIVE_TOPOLOGY_EXT              = PRIMITIVE_TOPOLOGY,
	VIEWPORT_WITH_COUNT_EXT             = VIEWPORT_WITH_COUNT,
	SCISSOR_WITH_COUNT_EXT              = SCISSOR_WITH_COUNT,
	VERTEX_INPUT_BINDING_STRIDE_EXT     = VERTEX_INPUT_BINDING_STRIDE,
	DEPTH_TEST_ENABLE_EXT               = DEPTH_TEST_ENABLE,
	DEPTH_WRITE_ENABLE_EXT              = DEPTH_WRITE_ENABLE,
	DEPTH_COMPARE_OP_EXT                = DEPTH_COMPARE_OP,
	DEPTH_BOUNDS_TEST_ENABLE_EXT        = DEPTH_BOUNDS_TEST_ENABLE,
	STENCIL_TEST_ENABLE_EXT             = STENCIL_TEST_ENABLE,
	STENCIL_OP_EXT                      = STENCIL_OP,
	RASTERIZER_DISCARD_ENABLE_EXT       = RASTERIZER_DISCARD_ENABLE,
	DEPTH_BIAS_ENABLE_EXT               = DEPTH_BIAS_ENABLE,
	PRIMITIVE_RESTART_ENABLE_EXT        = PRIMITIVE_RESTART_ENABLE,
}

EventCreateFlags :: distinct bit_set[EventCreateFlag; Flags]
EventCreateFlag :: enum Flags {
	DEVICE_ONLY     = 0,
	DEVICE_ONLY_KHR = DEVICE_ONLY,
}

ExternalFenceFeatureFlags :: distinct bit_set[ExternalFenceFeatureFlag; Flags]
ExternalFenceFeatureFlag :: enum Flags {
	EXPORTABLE     = 0,
	IMPORTABLE     = 1,
	EXPORTABLE_KHR = EXPORTABLE,
	IMPORTABLE_KHR = IMPORTABLE,
}

ExternalFenceHandleTypeFlags :: distinct bit_set[ExternalFenceHandleTypeFlag; Flags]
ExternalFenceHandleTypeFlag :: enum Flags {
	OPAQUE_FD            = 0,
	OPAQUE_WIN32         = 1,
	OPAQUE_WIN32_KMT     = 2,
	SYNC_FD              = 3,
	OPAQUE_FD_KHR        = OPAQUE_FD,
	OPAQUE_WIN32_KHR     = OPAQUE_WIN32,
	OPAQUE_WIN32_KMT_KHR = OPAQUE_WIN32_KMT,
	SYNC_FD_KHR          = SYNC_FD,
}

ExternalMemoryFeatureFlags :: distinct bit_set[ExternalMemoryFeatureFlag; Flags]
ExternalMemoryFeatureFlag :: enum Flags {
	DEDICATED_ONLY     = 0,
	EXPORTABLE         = 1,
	IMPORTABLE         = 2,
	DEDICATED_ONLY_KHR = DEDICATED_ONLY,
	EXPORTABLE_KHR     = EXPORTABLE,
	IMPORTABLE_KHR     = IMPORTABLE,
}

ExternalMemoryFeatureFlagsNV :: distinct bit_set[ExternalMemoryFeatureFlagNV; Flags]
ExternalMemoryFeatureFlagNV :: enum Flags {
	DEDICATED_ONLY = 0,
	EXPORTABLE     = 1,
	IMPORTABLE     = 2,
}

ExternalMemoryHandleTypeFlags :: distinct bit_set[ExternalMemoryHandleTypeFlag; Flags]
ExternalMemoryHandleTypeFlag :: enum Flags {
	OPAQUE_FD                       = 0,
	OPAQUE_WIN32                    = 1,
	OPAQUE_WIN32_KMT                = 2,
	D3D11_TEXTURE                   = 3,
	D3D11_TEXTURE_KMT               = 4,
	D3D12_HEAP                      = 5,
	D3D12_RESOURCE                  = 6,
	DMA_BUF_EXT                     = 9,
	ANDROID_HARDWARE_BUFFER_ANDROID = 10,
	HOST_ALLOCATION_EXT             = 7,
	HOST_MAPPED_FOREIGN_MEMORY_EXT  = 8,
	ZIRCON_VMO_FUCHSIA              = 11,
	RDMA_ADDRESS_NV                 = 12,
	OPAQUE_FD_KHR                   = OPAQUE_FD,
	OPAQUE_WIN32_KHR                = OPAQUE_WIN32,
	OPAQUE_WIN32_KMT_KHR            = OPAQUE_WIN32_KMT,
	D3D11_TEXTURE_KHR               = D3D11_TEXTURE,
	D3D11_TEXTURE_KMT_KHR           = D3D11_TEXTURE_KMT,
	D3D12_HEAP_KHR                  = D3D12_HEAP,
	D3D12_RESOURCE_KHR              = D3D12_RESOURCE,
}

ExternalMemoryHandleTypeFlagsNV :: distinct bit_set[ExternalMemoryHandleTypeFlagNV; Flags]
ExternalMemoryHandleTypeFlagNV :: enum Flags {
	OPAQUE_WIN32     = 0,
	OPAQUE_WIN32_KMT = 1,
	D3D11_IMAGE      = 2,
	D3D11_IMAGE_KMT  = 3,
}

ExternalSemaphoreFeatureFlags :: distinct bit_set[ExternalSemaphoreFeatureFlag; Flags]
ExternalSemaphoreFeatureFlag :: enum Flags {
	EXPORTABLE     = 0,
	IMPORTABLE     = 1,
	EXPORTABLE_KHR = EXPORTABLE,
	IMPORTABLE_KHR = IMPORTABLE,
}

ExternalSemaphoreHandleTypeFlags :: distinct bit_set[ExternalSemaphoreHandleTypeFlag; Flags]
ExternalSemaphoreHandleTypeFlag :: enum Flags {
	OPAQUE_FD            = 0,
	OPAQUE_WIN32         = 1,
	OPAQUE_WIN32_KMT     = 2,
	D3D12_FENCE          = 3,
	SYNC_FD              = 4,
	ZIRCON_EVENT_FUCHSIA = 7,
	D3D11_FENCE          = D3D12_FENCE,
	OPAQUE_FD_KHR        = OPAQUE_FD,
	OPAQUE_WIN32_KHR     = OPAQUE_WIN32,
	OPAQUE_WIN32_KMT_KHR = OPAQUE_WIN32_KMT,
	D3D12_FENCE_KHR      = D3D12_FENCE,
	SYNC_FD_KHR          = SYNC_FD,
}

FenceCreateFlags :: distinct bit_set[FenceCreateFlag; Flags]
FenceCreateFlag :: enum Flags {
	SIGNALED = 0,
}

FenceImportFlags :: distinct bit_set[FenceImportFlag; Flags]
FenceImportFlag :: enum Flags {
	TEMPORARY     = 0,
	TEMPORARY_KHR = TEMPORARY,
}

Filter :: enum c.int {
	NEAREST   = 0,
	LINEAR    = 1,
	CUBIC_IMG = 1000015000,
	CUBIC_EXT = CUBIC_IMG,
}

Format :: enum c.int {
	UNDEFINED                                      = 0,
	R4G4_UNORM_PACK8                               = 1,
	R4G4B4A4_UNORM_PACK16                          = 2,
	B4G4R4A4_UNORM_PACK16                          = 3,
	R5G6B5_UNORM_PACK16                            = 4,
	B5G6R5_UNORM_PACK16                            = 5,
	R5G5B5A1_UNORM_PACK16                          = 6,
	B5G5R5A1_UNORM_PACK16                          = 7,
	A1R5G5B5_UNORM_PACK16                          = 8,
	R8_UNORM                                       = 9,
	R8_SNORM                                       = 10,
	R8_USCALED                                     = 11,
	R8_SSCALED                                     = 12,
	R8_UINT                                        = 13,
	R8_SINT                                        = 14,
	R8_SRGB                                        = 15,
	R8G8_UNORM                                     = 16,
	R8G8_SNORM                                     = 17,
	R8G8_USCALED                                   = 18,
	R8G8_SSCALED                                   = 19,
	R8G8_UINT                                      = 20,
	R8G8_SINT                                      = 21,
	R8G8_SRGB                                      = 22,
	R8G8B8_UNORM                                   = 23,
	R8G8B8_SNORM                                   = 24,
	R8G8B8_USCALED                                 = 25,
	R8G8B8_SSCALED                                 = 26,
	R8G8B8_UINT                                    = 27,
	R8G8B8_SINT                                    = 28,
	R8G8B8_SRGB                                    = 29,
	B8G8R8_UNORM                                   = 30,
	B8G8R8_SNORM                                   = 31,
	B8G8R8_USCALED                                 = 32,
	B8G8R8_SSCALED                                 = 33,
	B8G8R8_UINT                                    = 34,
	B8G8R8_SINT                                    = 35,
	B8G8R8_SRGB                                    = 36,
	R8G8B8A8_UNORM                                 = 37,
	R8G8B8A8_SNORM                                 = 38,
	R8G8B8A8_USCALED                               = 39,
	R8G8B8A8_SSCALED                               = 40,
	R8G8B8A8_UINT                                  = 41,
	R8G8B8A8_SINT                                  = 42,
	R8G8B8A8_SRGB                                  = 43,
	B8G8R8A8_UNORM                                 = 44,
	B8G8R8A8_SNORM                                 = 45,
	B8G8R8A8_USCALED                               = 46,
	B8G8R8A8_SSCALED                               = 47,
	B8G8R8A8_UINT                                  = 48,
	B8G8R8A8_SINT                                  = 49,
	B8G8R8A8_SRGB                                  = 50,
	A8B8G8R8_UNORM_PACK32                          = 51,
	A8B8G8R8_SNORM_PACK32                          = 52,
	A8B8G8R8_USCALED_PACK32                        = 53,
	A8B8G8R8_SSCALED_PACK32                        = 54,
	A8B8G8R8_UINT_PACK32                           = 55,
	A8B8G8R8_SINT_PACK32                           = 56,
	A8B8G8R8_SRGB_PACK32                           = 57,
	A2R10G10B10_UNORM_PACK32                       = 58,
	A2R10G10B10_SNORM_PACK32                       = 59,
	A2R10G10B10_USCALED_PACK32                     = 60,
	A2R10G10B10_SSCALED_PACK32                     = 61,
	A2R10G10B10_UINT_PACK32                        = 62,
	A2R10G10B10_SINT_PACK32                        = 63,
	A2B10G10R10_UNORM_PACK32                       = 64,
	A2B10G10R10_SNORM_PACK32                       = 65,
	A2B10G10R10_USCALED_PACK32                     = 66,
	A2B10G10R10_SSCALED_PACK32                     = 67,
	A2B10G10R10_UINT_PACK32                        = 68,
	A2B10G10R10_SINT_PACK32                        = 69,
	R16_UNORM                                      = 70,
	R16_SNORM                                      = 71,
	R16_USCALED                                    = 72,
	R16_SSCALED                                    = 73,
	R16_UINT                                       = 74,
	R16_SINT                                       = 75,
	R16_SFLOAT                                     = 76,
	R16G16_UNORM                                   = 77,
	R16G16_SNORM                                   = 78,
	R16G16_USCALED                                 = 79,
	R16G16_SSCALED                                 = 80,
	R16G16_UINT                                    = 81,
	R16G16_SINT                                    = 82,
	R16G16_SFLOAT                                  = 83,
	R16G16B16_UNORM                                = 84,
	R16G16B16_SNORM                                = 85,
	R16G16B16_USCALED                              = 86,
	R16G16B16_SSCALED                              = 87,
	R16G16B16_UINT                                 = 88,
	R16G16B16_SINT                                 = 89,
	R16G16B16_SFLOAT                               = 90,
	R16G16B16A16_UNORM                             = 91,
	R16G16B16A16_SNORM                             = 92,
	R16G16B16A16_USCALED                           = 93,
	R16G16B16A16_SSCALED                           = 94,
	R16G16B16A16_UINT                              = 95,
	R16G16B16A16_SINT                              = 96,
	R16G16B16A16_SFLOAT                            = 97,
	R32_UINT                                       = 98,
	R32_SINT                                       = 99,
	R32_SFLOAT                                     = 100,
	R32G32_UINT                                    = 101,
	R32G32_SINT                                    = 102,
	R32G32_SFLOAT                                  = 103,
	R32G32B32_UINT                                 = 104,
	R32G32B32_SINT                                 = 105,
	R32G32B32_SFLOAT                               = 106,
	R32G32B32A32_UINT                              = 107,
	R32G32B32A32_SINT                              = 108,
	R32G32B32A32_SFLOAT                            = 109,
	R64_UINT                                       = 110,
	R64_SINT                                       = 111,
	R64_SFLOAT                                     = 112,
	R64G64_UINT                                    = 113,
	R64G64_SINT                                    = 114,
	R64G64_SFLOAT                                  = 115,
	R64G64B64_UINT                                 = 116,
	R64G64B64_SINT                                 = 117,
	R64G64B64_SFLOAT                               = 118,
	R64G64B64A64_UINT                              = 119,
	R64G64B64A64_SINT                              = 120,
	R64G64B64A64_SFLOAT                            = 121,
	B10G11R11_UFLOAT_PACK32                        = 122,
	E5B9G9R9_UFLOAT_PACK32                         = 123,
	D16_UNORM                                      = 124,
	X8_D24_UNORM_PACK32                            = 125,
	D32_SFLOAT                                     = 126,
	S8_UINT                                        = 127,
	D16_UNORM_S8_UINT                              = 128,
	D24_UNORM_S8_UINT                              = 129,
	D32_SFLOAT_S8_UINT                             = 130,
	BC1_RGB_UNORM_BLOCK                            = 131,
	BC1_RGB_SRGB_BLOCK                             = 132,
	BC1_RGBA_UNORM_BLOCK                           = 133,
	BC1_RGBA_SRGB_BLOCK                            = 134,
	BC2_UNORM_BLOCK                                = 135,
	BC2_SRGB_BLOCK                                 = 136,
	BC3_UNORM_BLOCK                                = 137,
	BC3_SRGB_BLOCK                                 = 138,
	BC4_UNORM_BLOCK                                = 139,
	BC4_SNORM_BLOCK                                = 140,
	BC5_UNORM_BLOCK                                = 141,
	BC5_SNORM_BLOCK                                = 142,
	BC6H_UFLOAT_BLOCK                              = 143,
	BC6H_SFLOAT_BLOCK                              = 144,
	BC7_UNORM_BLOCK                                = 145,
	BC7_SRGB_BLOCK                                 = 146,
	ETC2_R8G8B8_UNORM_BLOCK                        = 147,
	ETC2_R8G8B8_SRGB_BLOCK                         = 148,
	ETC2_R8G8B8A1_UNORM_BLOCK                      = 149,
	ETC2_R8G8B8A1_SRGB_BLOCK                       = 150,
	ETC2_R8G8B8A8_UNORM_BLOCK                      = 151,
	ETC2_R8G8B8A8_SRGB_BLOCK                       = 152,
	EAC_R11_UNORM_BLOCK                            = 153,
	EAC_R11_SNORM_BLOCK                            = 154,
	EAC_R11G11_UNORM_BLOCK                         = 155,
	EAC_R11G11_SNORM_BLOCK                         = 156,
	ASTC_4x4_UNORM_BLOCK                           = 157,
	ASTC_4x4_SRGB_BLOCK                            = 158,
	ASTC_5x4_UNORM_BLOCK                           = 159,
	ASTC_5x4_SRGB_BLOCK                            = 160,
	ASTC_5x5_UNORM_BLOCK                           = 161,
	ASTC_5x5_SRGB_BLOCK                            = 162,
	ASTC_6x5_UNORM_BLOCK                           = 163,
	ASTC_6x5_SRGB_BLOCK                            = 164,
	ASTC_6x6_UNORM_BLOCK                           = 165,
	ASTC_6x6_SRGB_BLOCK                            = 166,
	ASTC_8x5_UNORM_BLOCK                           = 167,
	ASTC_8x5_SRGB_BLOCK                            = 168,
	ASTC_8x6_UNORM_BLOCK                           = 169,
	ASTC_8x6_SRGB_BLOCK                            = 170,
	ASTC_8x8_UNORM_BLOCK                           = 171,
	ASTC_8x8_SRGB_BLOCK                            = 172,
	ASTC_10x5_UNORM_BLOCK                          = 173,
	ASTC_10x5_SRGB_BLOCK                           = 174,
	ASTC_10x6_UNORM_BLOCK                          = 175,
	ASTC_10x6_SRGB_BLOCK                           = 176,
	ASTC_10x8_UNORM_BLOCK                          = 177,
	ASTC_10x8_SRGB_BLOCK                           = 178,
	ASTC_10x10_UNORM_BLOCK                         = 179,
	ASTC_10x10_SRGB_BLOCK                          = 180,
	ASTC_12x10_UNORM_BLOCK                         = 181,
	ASTC_12x10_SRGB_BLOCK                          = 182,
	ASTC_12x12_UNORM_BLOCK                         = 183,
	ASTC_12x12_SRGB_BLOCK                          = 184,
	G8B8G8R8_422_UNORM                             = 1000156000,
	B8G8R8G8_422_UNORM                             = 1000156001,
	G8_B8_R8_3PLANE_420_UNORM                      = 1000156002,
	G8_B8R8_2PLANE_420_UNORM                       = 1000156003,
	G8_B8_R8_3PLANE_422_UNORM                      = 1000156004,
	G8_B8R8_2PLANE_422_UNORM                       = 1000156005,
	G8_B8_R8_3PLANE_444_UNORM                      = 1000156006,
	R10X6_UNORM_PACK16                             = 1000156007,
	R10X6G10X6_UNORM_2PACK16                       = 1000156008,
	R10X6G10X6B10X6A10X6_UNORM_4PACK16             = 1000156009,
	G10X6B10X6G10X6R10X6_422_UNORM_4PACK16         = 1000156010,
	B10X6G10X6R10X6G10X6_422_UNORM_4PACK16         = 1000156011,
	G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16     = 1000156012,
	G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16      = 1000156013,
	G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16     = 1000156014,
	G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16      = 1000156015,
	G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16     = 1000156016,
	R12X4_UNORM_PACK16                             = 1000156017,
	R12X4G12X4_UNORM_2PACK16                       = 1000156018,
	R12X4G12X4B12X4A12X4_UNORM_4PACK16             = 1000156019,
	G12X4B12X4G12X4R12X4_422_UNORM_4PACK16         = 1000156020,
	B12X4G12X4R12X4G12X4_422_UNORM_4PACK16         = 1000156021,
	G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16     = 1000156022,
	G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16      = 1000156023,
	G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16     = 1000156024,
	G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16      = 1000156025,
	G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16     = 1000156026,
	G16B16G16R16_422_UNORM                         = 1000156027,
	B16G16R16G16_422_UNORM                         = 1000156028,
	G16_B16_R16_3PLANE_420_UNORM                   = 1000156029,
	G16_B16R16_2PLANE_420_UNORM                    = 1000156030,
	G16_B16_R16_3PLANE_422_UNORM                   = 1000156031,
	G16_B16R16_2PLANE_422_UNORM                    = 1000156032,
	G16_B16_R16_3PLANE_444_UNORM                   = 1000156033,
	G8_B8R8_2PLANE_444_UNORM                       = 1000330000,
	G10X6_B10X6R10X6_2PLANE_444_UNORM_3PACK16      = 1000330001,
	G12X4_B12X4R12X4_2PLANE_444_UNORM_3PACK16      = 1000330002,
	G16_B16R16_2PLANE_444_UNORM                    = 1000330003,
	A4R4G4B4_UNORM_PACK16                          = 1000340000,
	A4B4G4R4_UNORM_PACK16                          = 1000340001,
	ASTC_4x4_SFLOAT_BLOCK                          = 1000066000,
	ASTC_5x4_SFLOAT_BLOCK                          = 1000066001,
	ASTC_5x5_SFLOAT_BLOCK                          = 1000066002,
	ASTC_6x5_SFLOAT_BLOCK                          = 1000066003,
	ASTC_6x6_SFLOAT_BLOCK                          = 1000066004,
	ASTC_8x5_SFLOAT_BLOCK                          = 1000066005,
	ASTC_8x6_SFLOAT_BLOCK                          = 1000066006,
	ASTC_8x8_SFLOAT_BLOCK                          = 1000066007,
	ASTC_10x5_SFLOAT_BLOCK                         = 1000066008,
	ASTC_10x6_SFLOAT_BLOCK                         = 1000066009,
	ASTC_10x8_SFLOAT_BLOCK                         = 1000066010,
	ASTC_10x10_SFLOAT_BLOCK                        = 1000066011,
	ASTC_12x10_SFLOAT_BLOCK                        = 1000066012,
	ASTC_12x12_SFLOAT_BLOCK                        = 1000066013,
	PVRTC1_2BPP_UNORM_BLOCK_IMG                    = 1000054000,
	PVRTC1_4BPP_UNORM_BLOCK_IMG                    = 1000054001,
	PVRTC2_2BPP_UNORM_BLOCK_IMG                    = 1000054002,
	PVRTC2_4BPP_UNORM_BLOCK_IMG                    = 1000054003,
	PVRTC1_2BPP_SRGB_BLOCK_IMG                     = 1000054004,
	PVRTC1_4BPP_SRGB_BLOCK_IMG                     = 1000054005,
	PVRTC2_2BPP_SRGB_BLOCK_IMG                     = 1000054006,
	PVRTC2_4BPP_SRGB_BLOCK_IMG                     = 1000054007,
	ASTC_4x4_SFLOAT_BLOCK_EXT                      = ASTC_4x4_SFLOAT_BLOCK,
	ASTC_5x4_SFLOAT_BLOCK_EXT                      = ASTC_5x4_SFLOAT_BLOCK,
	ASTC_5x5_SFLOAT_BLOCK_EXT                      = ASTC_5x5_SFLOAT_BLOCK,
	ASTC_6x5_SFLOAT_BLOCK_EXT                      = ASTC_6x5_SFLOAT_BLOCK,
	ASTC_6x6_SFLOAT_BLOCK_EXT                      = ASTC_6x6_SFLOAT_BLOCK,
	ASTC_8x5_SFLOAT_BLOCK_EXT                      = ASTC_8x5_SFLOAT_BLOCK,
	ASTC_8x6_SFLOAT_BLOCK_EXT                      = ASTC_8x6_SFLOAT_BLOCK,
	ASTC_8x8_SFLOAT_BLOCK_EXT                      = ASTC_8x8_SFLOAT_BLOCK,
	ASTC_10x5_SFLOAT_BLOCK_EXT                     = ASTC_10x5_SFLOAT_BLOCK,
	ASTC_10x6_SFLOAT_BLOCK_EXT                     = ASTC_10x6_SFLOAT_BLOCK,
	ASTC_10x8_SFLOAT_BLOCK_EXT                     = ASTC_10x8_SFLOAT_BLOCK,
	ASTC_10x10_SFLOAT_BLOCK_EXT                    = ASTC_10x10_SFLOAT_BLOCK,
	ASTC_12x10_SFLOAT_BLOCK_EXT                    = ASTC_12x10_SFLOAT_BLOCK,
	ASTC_12x12_SFLOAT_BLOCK_EXT                    = ASTC_12x12_SFLOAT_BLOCK,
	G8B8G8R8_422_UNORM_KHR                         = G8B8G8R8_422_UNORM,
	B8G8R8G8_422_UNORM_KHR                         = B8G8R8G8_422_UNORM,
	G8_B8_R8_3PLANE_420_UNORM_KHR                  = G8_B8_R8_3PLANE_420_UNORM,
	G8_B8R8_2PLANE_420_UNORM_KHR                   = G8_B8R8_2PLANE_420_UNORM,
	G8_B8_R8_3PLANE_422_UNORM_KHR                  = G8_B8_R8_3PLANE_422_UNORM,
	G8_B8R8_2PLANE_422_UNORM_KHR                   = G8_B8R8_2PLANE_422_UNORM,
	G8_B8_R8_3PLANE_444_UNORM_KHR                  = G8_B8_R8_3PLANE_444_UNORM,
	R10X6_UNORM_PACK16_KHR                         = R10X6_UNORM_PACK16,
	R10X6G10X6_UNORM_2PACK16_KHR                   = R10X6G10X6_UNORM_2PACK16,
	R10X6G10X6B10X6A10X6_UNORM_4PACK16_KHR         = R10X6G10X6B10X6A10X6_UNORM_4PACK16,
	G10X6B10X6G10X6R10X6_422_UNORM_4PACK16_KHR     = G10X6B10X6G10X6R10X6_422_UNORM_4PACK16,
	B10X6G10X6R10X6G10X6_422_UNORM_4PACK16_KHR     = B10X6G10X6R10X6G10X6_422_UNORM_4PACK16,
	G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16_KHR = G10X6_B10X6_R10X6_3PLANE_420_UNORM_3PACK16,
	G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16_KHR  = G10X6_B10X6R10X6_2PLANE_420_UNORM_3PACK16,
	G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16_KHR = G10X6_B10X6_R10X6_3PLANE_422_UNORM_3PACK16,
	G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16_KHR  = G10X6_B10X6R10X6_2PLANE_422_UNORM_3PACK16,
	G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16_KHR = G10X6_B10X6_R10X6_3PLANE_444_UNORM_3PACK16,
	R12X4_UNORM_PACK16_KHR                         = R12X4_UNORM_PACK16,
	R12X4G12X4_UNORM_2PACK16_KHR                   = R12X4G12X4_UNORM_2PACK16,
	R12X4G12X4B12X4A12X4_UNORM_4PACK16_KHR         = R12X4G12X4B12X4A12X4_UNORM_4PACK16,
	G12X4B12X4G12X4R12X4_422_UNORM_4PACK16_KHR     = G12X4B12X4G12X4R12X4_422_UNORM_4PACK16,
	B12X4G12X4R12X4G12X4_422_UNORM_4PACK16_KHR     = B12X4G12X4R12X4G12X4_422_UNORM_4PACK16,
	G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16_KHR = G12X4_B12X4_R12X4_3PLANE_420_UNORM_3PACK16,
	G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16_KHR  = G12X4_B12X4R12X4_2PLANE_420_UNORM_3PACK16,
	G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16_KHR = G12X4_B12X4_R12X4_3PLANE_422_UNORM_3PACK16,
	G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16_KHR  = G12X4_B12X4R12X4_2PLANE_422_UNORM_3PACK16,
	G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16_KHR = G12X4_B12X4_R12X4_3PLANE_444_UNORM_3PACK16,
	G16B16G16R16_422_UNORM_KHR                     = G16B16G16R16_422_UNORM,
	B16G16R16G16_422_UNORM_KHR                     = B16G16R16G16_422_UNORM,
	G16_B16_R16_3PLANE_420_UNORM_KHR               = G16_B16_R16_3PLANE_420_UNORM,
	G16_B16R16_2PLANE_420_UNORM_KHR                = G16_B16R16_2PLANE_420_UNORM,
	G16_B16_R16_3PLANE_422_UNORM_KHR               = G16_B16_R16_3PLANE_422_UNORM,
	G16_B16R16_2PLANE_422_UNORM_KHR                = G16_B16R16_2PLANE_422_UNORM,
	G16_B16_R16_3PLANE_444_UNORM_KHR               = G16_B16_R16_3PLANE_444_UNORM,
	G8_B8R8_2PLANE_444_UNORM_EXT                   = G8_B8R8_2PLANE_444_UNORM,
	G10X6_B10X6R10X6_2PLANE_444_UNORM_3PACK16_EXT  = G10X6_B10X6R10X6_2PLANE_444_UNORM_3PACK16,
	G12X4_B12X4R12X4_2PLANE_444_UNORM_3PACK16_EXT  = G12X4_B12X4R12X4_2PLANE_444_UNORM_3PACK16,
	G16_B16R16_2PLANE_444_UNORM_EXT                = G16_B16R16_2PLANE_444_UNORM,
	A4R4G4B4_UNORM_PACK16_EXT                      = A4R4G4B4_UNORM_PACK16,
	A4B4G4R4_UNORM_PACK16_EXT                      = A4B4G4R4_UNORM_PACK16,
}

FormatFeatureFlags :: distinct bit_set[FormatFeatureFlag; Flags]
FormatFeatureFlag :: enum Flags {
	SAMPLED_IMAGE                                                               = 0,
	STORAGE_IMAGE                                                               = 1,
	STORAGE_IMAGE_ATOMIC                                                        = 2,
	UNIFORM_TEXEL_BUFFER                                                        = 3,
	STORAGE_TEXEL_BUFFER                                                        = 4,
	STORAGE_TEXEL_BUFFER_ATOMIC                                                 = 5,
	VERTEX_BUFFER                                                               = 6,
	COLOR_ATTACHMENT                                                            = 7,
	COLOR_ATTACHMENT_BLEND                                                      = 8,
	DEPTH_STENCIL_ATTACHMENT                                                    = 9,
	BLIT_SRC                                                                    = 10,
	BLIT_DST                                                                    = 11,
	SAMPLED_IMAGE_FILTER_LINEAR                                                 = 12,
	TRANSFER_SRC                                                                = 14,
	TRANSFER_DST                                                                = 15,
	MIDPOINT_CHROMA_SAMPLES                                                     = 17,
	SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER                                = 18,
	SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER               = 19,
	SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT               = 20,
	SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE     = 21,
	DISJOINT                                                                    = 22,
	COSITED_CHROMA_SAMPLES                                                      = 23,
	SAMPLED_IMAGE_FILTER_MINMAX                                                 = 16,
	SAMPLED_IMAGE_FILTER_CUBIC_IMG                                              = 13,
	VIDEO_DECODE_OUTPUT_KHR                                                     = 25,
	VIDEO_DECODE_DPB_KHR                                                        = 26,
	ACCELERATION_STRUCTURE_VERTEX_BUFFER_KHR                                    = 29,
	FRAGMENT_DENSITY_MAP_EXT                                                    = 24,
	FRAGMENT_SHADING_RATE_ATTACHMENT_KHR                                        = 30,
	VIDEO_ENCODE_INPUT_KHR                                                      = 27,
	VIDEO_ENCODE_DPB_KHR                                                        = 28,
	TRANSFER_SRC_KHR                                                            = TRANSFER_SRC,
	TRANSFER_DST_KHR                                                            = TRANSFER_DST,
	SAMPLED_IMAGE_FILTER_MINMAX_EXT                                             = SAMPLED_IMAGE_FILTER_MINMAX,
	MIDPOINT_CHROMA_SAMPLES_KHR                                                 = MIDPOINT_CHROMA_SAMPLES,
	SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER_KHR                            = SAMPLED_IMAGE_YCBCR_CONVERSION_LINEAR_FILTER,
	SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER_KHR           = SAMPLED_IMAGE_YCBCR_CONVERSION_SEPARATE_RECONSTRUCTION_FILTER,
	SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_KHR           = SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT,
	SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE_KHR = SAMPLED_IMAGE_YCBCR_CONVERSION_CHROMA_RECONSTRUCTION_EXPLICIT_FORCEABLE,
	DISJOINT_KHR                                                                = DISJOINT,
	COSITED_CHROMA_SAMPLES_KHR                                                  = COSITED_CHROMA_SAMPLES,
	SAMPLED_IMAGE_FILTER_CUBIC_EXT                                              = SAMPLED_IMAGE_FILTER_CUBIC_IMG,
}

FragmentShadingRateCombinerOpKHR :: enum c.int {
	KEEP    = 0,
	REPLACE = 1,
	MIN     = 2,
	MAX     = 3,
	MUL     = 4,
}

FragmentShadingRateNV :: enum c.int {
	_1_INVOCATION_PER_PIXEL      = 0,
	_1_INVOCATION_PER_1X2_PIXELS = 1,
	_1_INVOCATION_PER_2X1_PIXELS = 4,
	_1_INVOCATION_PER_2X2_PIXELS = 5,
	_1_INVOCATION_PER_2X4_PIXELS = 6,
	_1_INVOCATION_PER_4X2_PIXELS = 9,
	_1_INVOCATION_PER_4X4_PIXELS = 10,
	_2_INVOCATIONS_PER_PIXEL     = 11,
	_4_INVOCATIONS_PER_PIXEL     = 12,
	_8_INVOCATIONS_PER_PIXEL     = 13,
	_16_INVOCATIONS_PER_PIXEL    = 14,
	NO_INVOCATIONS               = 15,
}

FragmentShadingRateTypeNV :: enum c.int {
	FRAGMENT_SIZE = 0,
	ENUMS         = 1,
}

FramebufferCreateFlags :: distinct bit_set[FramebufferCreateFlag; Flags]
FramebufferCreateFlag :: enum Flags {
	IMAGELESS     = 0,
	IMAGELESS_KHR = IMAGELESS,
}

FrontFace :: enum c.int {
	COUNTER_CLOCKWISE = 0,
	CLOCKWISE         = 1,
}

FullScreenExclusiveEXT :: enum c.int {
	DEFAULT                = 0,
	ALLOWED                = 1,
	DISALLOWED             = 2,
	APPLICATION_CONTROLLED = 3,
}

GeometryFlagsKHR :: distinct bit_set[GeometryFlagKHR; Flags]
GeometryFlagKHR :: enum Flags {
	OPAQUE                             = 0,
	NO_DUPLICATE_ANY_HIT_INVOCATION    = 1,
	OPAQUE_NV                          = OPAQUE,
	NO_DUPLICATE_ANY_HIT_INVOCATION_NV = NO_DUPLICATE_ANY_HIT_INVOCATION,
}

GeometryInstanceFlagsKHR :: distinct bit_set[GeometryInstanceFlagKHR; Flags]
GeometryInstanceFlagKHR :: enum Flags {
	TRIANGLE_FACING_CULL_DISABLE       = 0,
	TRIANGLE_FLIP_FACING               = 1,
	FORCE_OPAQUE                       = 2,
	FORCE_NO_OPAQUE                    = 3,
	TRIANGLE_FRONT_COUNTERCLOCKWISE    = TRIANGLE_FLIP_FACING,
	TRIANGLE_CULL_DISABLE_NV           = TRIANGLE_FACING_CULL_DISABLE,
	TRIANGLE_FRONT_COUNTERCLOCKWISE_NV = TRIANGLE_FRONT_COUNTERCLOCKWISE,
	FORCE_OPAQUE_NV                    = FORCE_OPAQUE,
	FORCE_NO_OPAQUE_NV                 = FORCE_NO_OPAQUE,
}

GeometryTypeKHR :: enum c.int {
	TRIANGLES    = 0,
	AABBS        = 1,
	INSTANCES    = 2,
	TRIANGLES_NV = TRIANGLES,
	AABBS_NV     = AABBS,
}

GraphicsPipelineLibraryFlagsEXT :: distinct bit_set[GraphicsPipelineLibraryFlagEXT; Flags]
GraphicsPipelineLibraryFlagEXT :: enum Flags {
	VERTEX_INPUT_INTERFACE    = 0,
	PRE_RASTERIZATION_SHADERS = 1,
	FRAGMENT_SHADER           = 2,
	FRAGMENT_OUTPUT_INTERFACE = 3,
}

ImageAspectFlags :: distinct bit_set[ImageAspectFlag; Flags]
ImageAspectFlag :: enum Flags {
	COLOR              = 0,
	DEPTH              = 1,
	STENCIL            = 2,
	METADATA           = 3,
	PLANE_0            = 4,
	PLANE_1            = 5,
	PLANE_2            = 6,
	MEMORY_PLANE_0_EXT = 7,
	MEMORY_PLANE_1_EXT = 8,
	MEMORY_PLANE_2_EXT = 9,
	MEMORY_PLANE_3_EXT = 10,
	PLANE_0_KHR        = PLANE_0,
	PLANE_1_KHR        = PLANE_1,
	PLANE_2_KHR        = PLANE_2,
}

ImageAspectFlags_NONE :: ImageAspectFlags{}


ImageCreateFlags :: distinct bit_set[ImageCreateFlag; Flags]
ImageCreateFlag :: enum Flags {
	SPARSE_BINDING                        = 0,
	SPARSE_RESIDENCY                      = 1,
	SPARSE_ALIASED                        = 2,
	MUTABLE_FORMAT                        = 3,
	CUBE_COMPATIBLE                       = 4,
	ALIAS                                 = 10,
	SPLIT_INSTANCE_BIND_REGIONS           = 6,
	D2_ARRAY_COMPATIBLE                   = 5,
	BLOCK_TEXEL_VIEW_COMPATIBLE           = 7,
	EXTENDED_USAGE                        = 8,
	PROTECTED                             = 11,
	DISJOINT                              = 9,
	CORNER_SAMPLED_NV                     = 13,
	SAMPLE_LOCATIONS_COMPATIBLE_DEPTH_EXT = 12,
	SUBSAMPLED_EXT                        = 14,
	D2_VIEW_COMPATIBLE_EXT                = 17,
	FRAGMENT_DENSITY_MAP_OFFSET_QCOM      = 15,
	SPLIT_INSTANCE_BIND_REGIONS_KHR       = SPLIT_INSTANCE_BIND_REGIONS,
	D2_ARRAY_COMPATIBLE_KHR               = D2_ARRAY_COMPATIBLE,
	BLOCK_TEXEL_VIEW_COMPATIBLE_KHR       = BLOCK_TEXEL_VIEW_COMPATIBLE,
	EXTENDED_USAGE_KHR                    = EXTENDED_USAGE,
	DISJOINT_KHR                          = DISJOINT,
	ALIAS_KHR                             = ALIAS,
}

ImageLayout :: enum c.int {
	UNDEFINED                                      = 0,
	GENERAL                                        = 1,
	COLOR_ATTACHMENT_OPTIMAL                       = 2,
	DEPTH_STENCIL_ATTACHMENT_OPTIMAL               = 3,
	DEPTH_STENCIL_READ_ONLY_OPTIMAL                = 4,
	SHADER_READ_ONLY_OPTIMAL                       = 5,
	TRANSFER_SRC_OPTIMAL                           = 6,
	TRANSFER_DST_OPTIMAL                           = 7,
	PREINITIALIZED                                 = 8,
	DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL     = 1000117000,
	DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL     = 1000117001,
	DEPTH_ATTACHMENT_OPTIMAL                       = 1000241000,
	DEPTH_READ_ONLY_OPTIMAL                        = 1000241001,
	STENCIL_ATTACHMENT_OPTIMAL                     = 1000241002,
	STENCIL_READ_ONLY_OPTIMAL                      = 1000241003,
	READ_ONLY_OPTIMAL                              = 1000314000,
	ATTACHMENT_OPTIMAL                             = 1000314001,
	PRESENT_SRC_KHR                                = 1000001002,
	VIDEO_DECODE_DST_KHR                           = 1000024000,
	VIDEO_DECODE_SRC_KHR                           = 1000024001,
	VIDEO_DECODE_DPB_KHR                           = 1000024002,
	SHARED_PRESENT_KHR                             = 1000111000,
	FRAGMENT_DENSITY_MAP_OPTIMAL_EXT               = 1000218000,
	FRAGMENT_SHADING_RATE_ATTACHMENT_OPTIMAL_KHR   = 1000164003,
	VIDEO_ENCODE_DST_KHR                           = 1000299000,
	VIDEO_ENCODE_SRC_KHR                           = 1000299001,
	VIDEO_ENCODE_DPB_KHR                           = 1000299002,
	DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL_KHR = DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL,
	DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL_KHR = DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL,
	SHADING_RATE_OPTIMAL_NV                        = FRAGMENT_SHADING_RATE_ATTACHMENT_OPTIMAL_KHR,
	DEPTH_ATTACHMENT_OPTIMAL_KHR                   = DEPTH_ATTACHMENT_OPTIMAL,
	DEPTH_READ_ONLY_OPTIMAL_KHR                    = DEPTH_READ_ONLY_OPTIMAL,
	STENCIL_ATTACHMENT_OPTIMAL_KHR                 = STENCIL_ATTACHMENT_OPTIMAL,
	STENCIL_READ_ONLY_OPTIMAL_KHR                  = STENCIL_READ_ONLY_OPTIMAL,
	READ_ONLY_OPTIMAL_KHR                          = READ_ONLY_OPTIMAL,
	ATTACHMENT_OPTIMAL_KHR                         = ATTACHMENT_OPTIMAL,
}

ImageTiling :: enum c.int {
	OPTIMAL                 = 0,
	LINEAR                  = 1,
	DRM_FORMAT_MODIFIER_EXT = 1000158000,
}

ImageType :: enum c.int {
	D1 = 0,
	D2 = 1,
	D3 = 2,
}

ImageUsageFlags :: distinct bit_set[ImageUsageFlag; Flags]
ImageUsageFlag :: enum Flags {
	TRANSFER_SRC                         = 0,
	TRANSFER_DST                         = 1,
	SAMPLED                              = 2,
	STORAGE                              = 3,
	COLOR_ATTACHMENT                     = 4,
	DEPTH_STENCIL_ATTACHMENT             = 5,
	TRANSIENT_ATTACHMENT                 = 6,
	INPUT_ATTACHMENT                     = 7,
	VIDEO_DECODE_DST_KHR                 = 10,
	VIDEO_DECODE_SRC_KHR                 = 11,
	VIDEO_DECODE_DPB_KHR                 = 12,
	FRAGMENT_DENSITY_MAP_EXT             = 9,
	FRAGMENT_SHADING_RATE_ATTACHMENT_KHR = 8,
	VIDEO_ENCODE_DST_KHR                 = 13,
	VIDEO_ENCODE_SRC_KHR                 = 14,
	VIDEO_ENCODE_DPB_KHR                 = 15,
	INVOCATION_MASK_HUAWEI               = 18,
	SHADING_RATE_IMAGE_NV                = FRAGMENT_SHADING_RATE_ATTACHMENT_KHR,
}

ImageViewCreateFlags :: distinct bit_set[ImageViewCreateFlag; Flags]
ImageViewCreateFlag :: enum Flags {
	FRAGMENT_DENSITY_MAP_DYNAMIC_EXT  = 0,
	FRAGMENT_DENSITY_MAP_DEFERRED_EXT = 1,
}

ImageViewType :: enum c.int {
	D1         = 0,
	D2         = 1,
	D3         = 2,
	CUBE       = 3,
	D1_ARRAY   = 4,
	D2_ARRAY   = 5,
	CUBE_ARRAY = 6,
}

IndexType :: enum c.int {
	UINT16    = 0,
	UINT32    = 1,
	NONE_KHR  = 1000165000,
	UINT8_EXT = 1000265000,
	NONE_NV   = NONE_KHR,
}

IndirectCommandsLayoutUsageFlagsNV :: distinct bit_set[IndirectCommandsLayoutUsageFlagNV; Flags]
IndirectCommandsLayoutUsageFlagNV :: enum Flags {
	EXPLICIT_PREPROCESS = 0,
	INDEXED_SEQUENCES   = 1,
	UNORDERED_SEQUENCES = 2,
}

IndirectCommandsTokenTypeNV :: enum c.int {
	SHADER_GROUP  = 0,
	STATE_FLAGS   = 1,
	INDEX_BUFFER  = 2,
	VERTEX_BUFFER = 3,
	PUSH_CONSTANT = 4,
	DRAW_INDEXED  = 5,
	DRAW          = 6,
	DRAW_TASKS    = 7,
}

IndirectStateFlagsNV :: distinct bit_set[IndirectStateFlagNV; Flags]
IndirectStateFlagNV :: enum Flags {
	FLAG_FRONTFACE = 0,
}

InstanceCreateFlags :: distinct bit_set[InstanceCreateFlag; Flags]
InstanceCreateFlag :: enum Flags {
	ENUMERATE_PORTABILITY_KHR = 0,
}

InternalAllocationType :: enum c.int {
	EXECUTABLE = 0,
}

LineRasterizationModeEXT :: enum c.int {
	DEFAULT            = 0,
	RECTANGULAR        = 1,
	BRESENHAM          = 2,
	RECTANGULAR_SMOOTH = 3,
}

LogicOp :: enum c.int {
	CLEAR         = 0,
	AND           = 1,
	AND_REVERSE   = 2,
	COPY          = 3,
	AND_INVERTED  = 4,
	NO_OP         = 5,
	XOR           = 6,
	OR            = 7,
	NOR           = 8,
	EQUIVALENT    = 9,
	INVERT        = 10,
	OR_REVERSE    = 11,
	COPY_INVERTED = 12,
	OR_INVERTED   = 13,
	NAND          = 14,
	SET           = 15,
}

MemoryAllocateFlags :: distinct bit_set[MemoryAllocateFlag; Flags]
MemoryAllocateFlag :: enum Flags {
	DEVICE_MASK                       = 0,
	DEVICE_ADDRESS                    = 1,
	DEVICE_ADDRESS_CAPTURE_REPLAY     = 2,
	DEVICE_MASK_KHR                   = DEVICE_MASK,
	DEVICE_ADDRESS_KHR                = DEVICE_ADDRESS,
	DEVICE_ADDRESS_CAPTURE_REPLAY_KHR = DEVICE_ADDRESS_CAPTURE_REPLAY,
}

MemoryHeapFlags :: distinct bit_set[MemoryHeapFlag; Flags]
MemoryHeapFlag :: enum Flags {
	DEVICE_LOCAL       = 0,
	MULTI_INSTANCE     = 1,
	MULTI_INSTANCE_KHR = MULTI_INSTANCE,
}

MemoryOverallocationBehaviorAMD :: enum c.int {
	DEFAULT    = 0,
	ALLOWED    = 1,
	DISALLOWED = 2,
}

MemoryPropertyFlags :: distinct bit_set[MemoryPropertyFlag; Flags]
MemoryPropertyFlag :: enum Flags {
	DEVICE_LOCAL        = 0,
	HOST_VISIBLE        = 1,
	HOST_COHERENT       = 2,
	HOST_CACHED         = 3,
	LAZILY_ALLOCATED    = 4,
	PROTECTED           = 5,
	DEVICE_COHERENT_AMD = 6,
	DEVICE_UNCACHED_AMD = 7,
	RDMA_CAPABLE_NV     = 8,
}

ObjectType :: enum c.int {
	UNKNOWN                         = 0,
	INSTANCE                        = 1,
	PHYSICAL_DEVICE                 = 2,
	DEVICE                          = 3,
	QUEUE                           = 4,
	SEMAPHORE                       = 5,
	COMMAND_BUFFER                  = 6,
	FENCE                           = 7,
	DEVICE_MEMORY                   = 8,
	BUFFER                          = 9,
	IMAGE                           = 10,
	EVENT                           = 11,
	QUERY_POOL                      = 12,
	BUFFER_VIEW                     = 13,
	IMAGE_VIEW                      = 14,
	SHADER_MODULE                   = 15,
	PIPELINE_CACHE                  = 16,
	PIPELINE_LAYOUT                 = 17,
	RENDER_PASS                     = 18,
	PIPELINE                        = 19,
	DESCRIPTOR_SET_LAYOUT           = 20,
	SAMPLER                         = 21,
	DESCRIPTOR_POOL                 = 22,
	DESCRIPTOR_SET                  = 23,
	FRAMEBUFFER                     = 24,
	COMMAND_POOL                    = 25,
	SAMPLER_YCBCR_CONVERSION        = 1000156000,
	DESCRIPTOR_UPDATE_TEMPLATE      = 1000085000,
	PRIVATE_DATA_SLOT               = 1000295000,
	SURFACE_KHR                     = 1000000000,
	SWAPCHAIN_KHR                   = 1000001000,
	DISPLAY_KHR                     = 1000002000,
	DISPLAY_MODE_KHR                = 1000002001,
	DEBUG_REPORT_CALLBACK_EXT       = 1000011000,
	VIDEO_SESSION_KHR               = 1000023000,
	VIDEO_SESSION_PARAMETERS_KHR    = 1000023001,
	CU_MODULE_NVX                   = 1000029000,
	CU_FUNCTION_NVX                 = 1000029001,
	DEBUG_UTILS_MESSENGER_EXT       = 1000128000,
	ACCELERATION_STRUCTURE_KHR      = 1000150000,
	VALIDATION_CACHE_EXT            = 1000160000,
	ACCELERATION_STRUCTURE_NV       = 1000165000,
	PERFORMANCE_CONFIGURATION_INTEL = 1000210000,
	DEFERRED_OPERATION_KHR          = 1000268000,
	INDIRECT_COMMANDS_LAYOUT_NV     = 1000277000,
	BUFFER_COLLECTION_FUCHSIA       = 1000366000,
	DESCRIPTOR_UPDATE_TEMPLATE_KHR  = DESCRIPTOR_UPDATE_TEMPLATE,
	SAMPLER_YCBCR_CONVERSION_KHR    = SAMPLER_YCBCR_CONVERSION,
	PRIVATE_DATA_SLOT_EXT           = PRIVATE_DATA_SLOT,
}

PeerMemoryFeatureFlags :: distinct bit_set[PeerMemoryFeatureFlag; Flags]
PeerMemoryFeatureFlag :: enum Flags {
	COPY_SRC        = 0,
	COPY_DST        = 1,
	GENERIC_SRC     = 2,
	GENERIC_DST     = 3,
	COPY_SRC_KHR    = COPY_SRC,
	COPY_DST_KHR    = COPY_DST,
	GENERIC_SRC_KHR = GENERIC_SRC,
	GENERIC_DST_KHR = GENERIC_DST,
}

PerformanceConfigurationTypeINTEL :: enum c.int {
	PERFORMANCE_CONFIGURATION_TYPE_COMMAND_QUEUE_METRICS_DISCOVERY_ACTIVATED_INTEL = 0,
}

PerformanceCounterDescriptionFlagsKHR :: distinct bit_set[PerformanceCounterDescriptionFlagKHR; Flags]
PerformanceCounterDescriptionFlagKHR :: enum Flags {
	PERFORMANCE_IMPACTING = 0,
	CONCURRENTLY_IMPACTED = 1,
}

PerformanceCounterScopeKHR :: enum c.int {
	COMMAND_BUFFER             = 0,
	RENDER_PASS                = 1,
	COMMAND                    = 2,
	QUERY_SCOPE_COMMAND_BUFFER = COMMAND_BUFFER,
	QUERY_SCOPE_RENDER_PASS    = RENDER_PASS,
	QUERY_SCOPE_COMMAND        = COMMAND,
}

PerformanceCounterStorageKHR :: enum c.int {
	INT32   = 0,
	INT64   = 1,
	UINT32  = 2,
	UINT64  = 3,
	FLOAT32 = 4,
	FLOAT64 = 5,
}

PerformanceCounterUnitKHR :: enum c.int {
	GENERIC          = 0,
	PERCENTAGE       = 1,
	NANOSECONDS      = 2,
	BYTES            = 3,
	BYTES_PER_SECOND = 4,
	KELVIN           = 5,
	WATTS            = 6,
	VOLTS            = 7,
	AMPS             = 8,
	HERTZ            = 9,
	CYCLES           = 10,
}

PerformanceOverrideTypeINTEL :: enum c.int {
	PERFORMANCE_OVERRIDE_TYPE_NULL_HARDWARE_INTEL    = 0,
	PERFORMANCE_OVERRIDE_TYPE_FLUSH_GPU_CACHES_INTEL = 1,
}

PerformanceParameterTypeINTEL :: enum c.int {
	PERFORMANCE_PARAMETER_TYPE_HW_COUNTERS_SUPPORTED_INTEL    = 0,
	PERFORMANCE_PARAMETER_TYPE_STREAM_MARKER_VALID_BITS_INTEL = 1,
}

PerformanceValueTypeINTEL :: enum c.int {
	PERFORMANCE_VALUE_TYPE_UINT32_INTEL = 0,
	PERFORMANCE_VALUE_TYPE_UINT64_INTEL = 1,
	PERFORMANCE_VALUE_TYPE_FLOAT_INTEL  = 2,
	PERFORMANCE_VALUE_TYPE_BOOL_INTEL   = 3,
	PERFORMANCE_VALUE_TYPE_STRING_INTEL = 4,
}

PhysicalDeviceType :: enum c.int {
	OTHER          = 0,
	INTEGRATED_GPU = 1,
	DISCRETE_GPU   = 2,
	VIRTUAL_GPU    = 3,
	CPU            = 4,
}

PipelineBindPoint :: enum c.int {
	GRAPHICS               = 0,
	COMPUTE                = 1,
	RAY_TRACING_KHR        = 1000165000,
	SUBPASS_SHADING_HUAWEI = 1000369003,
	RAY_TRACING_NV         = RAY_TRACING_KHR,
}

PipelineCacheCreateFlags :: distinct bit_set[PipelineCacheCreateFlag; Flags]
PipelineCacheCreateFlag :: enum Flags {
	EXTERNALLY_SYNCHRONIZED     = 0,
	EXTERNALLY_SYNCHRONIZED_EXT = EXTERNALLY_SYNCHRONIZED,
}

PipelineCacheHeaderVersion :: enum c.int {
	ONE = 1,
}

PipelineColorBlendStateCreateFlags :: distinct bit_set[PipelineColorBlendStateCreateFlag; Flags]
PipelineColorBlendStateCreateFlag :: enum Flags {
	RASTERIZATION_ORDER_ATTACHMENT_ACCESS_ARM = 0,
}

PipelineCompilerControlFlagsAMD :: distinct bit_set[PipelineCompilerControlFlagAMD; Flags]
PipelineCompilerControlFlagAMD :: enum Flags {
}

PipelineCreateFlags :: distinct bit_set[PipelineCreateFlag; Flags]
PipelineCreateFlag :: enum Flags {
	DISABLE_OPTIMIZATION                                                     = 0,
	ALLOW_DERIVATIVES                                                        = 1,
	DERIVATIVE                                                               = 2,
	VIEW_INDEX_FROM_DEVICE_INDEX                                             = 3,
	DISPATCH_BASE                                                            = 4,
	FAIL_ON_PIPELINE_COMPILE_REQUIRED                                        = 8,
	EARLY_RETURN_ON_FAILURE                                                  = 9,
	RENDERING_FRAGMENT_SHADING_RATE_ATTACHMENT_KHR                           = 21,
	RENDERING_FRAGMENT_DENSITY_MAP_ATTACHMENT_EXT                            = 22,
	RAY_TRACING_NO_NULL_ANY_HIT_SHADERS_KHR                                  = 14,
	RAY_TRACING_NO_NULL_CLOSEST_HIT_SHADERS_KHR                              = 15,
	RAY_TRACING_NO_NULL_MISS_SHADERS_KHR                                     = 16,
	RAY_TRACING_NO_NULL_INTERSECTION_SHADERS_KHR                             = 17,
	RAY_TRACING_SKIP_TRIANGLES_KHR                                           = 12,
	RAY_TRACING_SKIP_AABBS_KHR                                               = 13,
	RAY_TRACING_SHADER_GROUP_HANDLE_CAPTURE_REPLAY_KHR                       = 19,
	DEFER_COMPILE_NV                                                         = 5,
	CAPTURE_STATISTICS_KHR                                                   = 6,
	CAPTURE_INTERNAL_REPRESENTATIONS_KHR                                     = 7,
	INDIRECT_BINDABLE_NV                                                     = 18,
	LIBRARY_KHR                                                              = 11,
	RETAIN_LINK_TIME_OPTIMIZATION_INFO_EXT                                   = 23,
	LINK_TIME_OPTIMIZATION_EXT                                               = 10,
	RAY_TRACING_ALLOW_MOTION_NV                                              = 20,
	PIPELINE_RASTERIZATION_STATE_CREATE_FRAGMENT_SHADING_RATE_ATTACHMENT_KHR = RENDERING_FRAGMENT_SHADING_RATE_ATTACHMENT_KHR,
	PIPELINE_RASTERIZATION_STATE_CREATE_FRAGMENT_DENSITY_MAP_ATTACHMENT_EXT  = RENDERING_FRAGMENT_DENSITY_MAP_ATTACHMENT_EXT,
	VIEW_INDEX_FROM_DEVICE_INDEX_KHR                                         = VIEW_INDEX_FROM_DEVICE_INDEX,
	DISPATCH_BASE_KHR                                                        = DISPATCH_BASE,
	FAIL_ON_PIPELINE_COMPILE_REQUIRED_EXT                                    = FAIL_ON_PIPELINE_COMPILE_REQUIRED,
	EARLY_RETURN_ON_FAILURE_EXT                                              = EARLY_RETURN_ON_FAILURE,
}

PipelineCreationFeedbackFlags :: distinct bit_set[PipelineCreationFeedbackFlag; Flags]
PipelineCreationFeedbackFlag :: enum Flags {
	VALID                              = 0,
	APPLICATION_PIPELINE_CACHE_HIT     = 1,
	BASE_PIPELINE_ACCELERATION         = 2,
	VALID_EXT                          = VALID,
	APPLICATION_PIPELINE_CACHE_HIT_EXT = APPLICATION_PIPELINE_CACHE_HIT,
	BASE_PIPELINE_ACCELERATION_EXT     = BASE_PIPELINE_ACCELERATION,
}

PipelineDepthStencilStateCreateFlags :: distinct bit_set[PipelineDepthStencilStateCreateFlag; Flags]
PipelineDepthStencilStateCreateFlag :: enum Flags {
	RASTERIZATION_ORDER_ATTACHMENT_DEPTH_ACCESS_ARM   = 0,
	RASTERIZATION_ORDER_ATTACHMENT_STENCIL_ACCESS_ARM = 1,
}

PipelineExecutableStatisticFormatKHR :: enum c.int {
	BOOL32  = 0,
	INT64   = 1,
	UINT64  = 2,
	FLOAT64 = 3,
}

PipelineLayoutCreateFlags :: distinct bit_set[PipelineLayoutCreateFlag; Flags]
PipelineLayoutCreateFlag :: enum Flags {
	INDEPENDENT_SETS_EXT = 1,
}

PipelineShaderStageCreateFlags :: distinct bit_set[PipelineShaderStageCreateFlag; Flags]
PipelineShaderStageCreateFlag :: enum Flags {
	ALLOW_VARYING_SUBGROUP_SIZE     = 0,
	REQUIRE_FULL_SUBGROUPS          = 1,
	ALLOW_VARYING_SUBGROUP_SIZE_EXT = ALLOW_VARYING_SUBGROUP_SIZE,
	REQUIRE_FULL_SUBGROUPS_EXT      = REQUIRE_FULL_SUBGROUPS,
}

PipelineStageFlags :: distinct bit_set[PipelineStageFlag; Flags]
PipelineStageFlag :: enum Flags {
	TOP_OF_PIPE                          = 0,
	DRAW_INDIRECT                        = 1,
	VERTEX_INPUT                         = 2,
	VERTEX_SHADER                        = 3,
	TESSELLATION_CONTROL_SHADER          = 4,
	TESSELLATION_EVALUATION_SHADER       = 5,
	GEOMETRY_SHADER                      = 6,
	FRAGMENT_SHADER                      = 7,
	EARLY_FRAGMENT_TESTS                 = 8,
	LATE_FRAGMENT_TESTS                  = 9,
	COLOR_ATTACHMENT_OUTPUT              = 10,
	COMPUTE_SHADER                       = 11,
	TRANSFER                             = 12,
	BOTTOM_OF_PIPE                       = 13,
	HOST                                 = 14,
	ALL_GRAPHICS                         = 15,
	ALL_COMMANDS                         = 16,
	TRANSFORM_FEEDBACK_EXT               = 24,
	CONDITIONAL_RENDERING_EXT            = 18,
	ACCELERATION_STRUCTURE_BUILD_KHR     = 25,
	RAY_TRACING_SHADER_KHR               = 21,
	TASK_SHADER_NV                       = 19,
	MESH_SHADER_NV                       = 20,
	FRAGMENT_DENSITY_PROCESS_EXT         = 23,
	FRAGMENT_SHADING_RATE_ATTACHMENT_KHR = 22,
	COMMAND_PREPROCESS_NV                = 17,
	SHADING_RATE_IMAGE_NV                = FRAGMENT_SHADING_RATE_ATTACHMENT_KHR,
	RAY_TRACING_SHADER_NV                = RAY_TRACING_SHADER_KHR,
	ACCELERATION_STRUCTURE_BUILD_NV      = ACCELERATION_STRUCTURE_BUILD_KHR,
}

PipelineStageFlags_NONE :: PipelineStageFlags{}


PointClippingBehavior :: enum c.int {
	ALL_CLIP_PLANES           = 0,
	USER_CLIP_PLANES_ONLY     = 1,
	ALL_CLIP_PLANES_KHR       = ALL_CLIP_PLANES,
	USER_CLIP_PLANES_ONLY_KHR = USER_CLIP_PLANES_ONLY,
}

PolygonMode :: enum c.int {
	FILL              = 0,
	LINE              = 1,
	POINT             = 2,
	FILL_RECTANGLE_NV = 1000153000,
}

PresentModeKHR :: enum c.int {
	IMMEDIATE                 = 0,
	MAILBOX                   = 1,
	FIFO                      = 2,
	FIFO_RELAXED              = 3,
	SHARED_DEMAND_REFRESH     = 1000111000,
	SHARED_CONTINUOUS_REFRESH = 1000111001,
}

PrimitiveTopology :: enum c.int {
	POINT_LIST                    = 0,
	LINE_LIST                     = 1,
	LINE_STRIP                    = 2,
	TRIANGLE_LIST                 = 3,
	TRIANGLE_STRIP                = 4,
	TRIANGLE_FAN                  = 5,
	LINE_LIST_WITH_ADJACENCY      = 6,
	LINE_STRIP_WITH_ADJACENCY     = 7,
	TRIANGLE_LIST_WITH_ADJACENCY  = 8,
	TRIANGLE_STRIP_WITH_ADJACENCY = 9,
	PATCH_LIST                    = 10,
}

ProvokingVertexModeEXT :: enum c.int {
	FIRST_VERTEX = 0,
	LAST_VERTEX  = 1,
}

QueryControlFlags :: distinct bit_set[QueryControlFlag; Flags]
QueryControlFlag :: enum Flags {
	PRECISE = 0,
}

QueryPipelineStatisticFlags :: distinct bit_set[QueryPipelineStatisticFlag; Flags]
QueryPipelineStatisticFlag :: enum Flags {
	INPUT_ASSEMBLY_VERTICES                    = 0,
	INPUT_ASSEMBLY_PRIMITIVES                  = 1,
	VERTEX_SHADER_INVOCATIONS                  = 2,
	GEOMETRY_SHADER_INVOCATIONS                = 3,
	GEOMETRY_SHADER_PRIMITIVES                 = 4,
	CLIPPING_INVOCATIONS                       = 5,
	CLIPPING_PRIMITIVES                        = 6,
	FRAGMENT_SHADER_INVOCATIONS                = 7,
	TESSELLATION_CONTROL_SHADER_PATCHES        = 8,
	TESSELLATION_EVALUATION_SHADER_INVOCATIONS = 9,
	COMPUTE_SHADER_INVOCATIONS                 = 10,
}

QueryPoolSamplingModeINTEL :: enum c.int {
	QUERY_POOL_SAMPLING_MODE_MANUAL_INTEL = 0,
}

QueryResultFlags :: distinct bit_set[QueryResultFlag; Flags]
QueryResultFlag :: enum Flags {
	_64               = 0,
	WAIT              = 1,
	WITH_AVAILABILITY = 2,
	PARTIAL           = 3,
	WITH_STATUS_KHR   = 4,
}

QueryType :: enum c.int {
	OCCLUSION                                     = 0,
	PIPELINE_STATISTICS                           = 1,
	TIMESTAMP                                     = 2,
	RESULT_STATUS_ONLY_KHR                        = 1000023000,
	TRANSFORM_FEEDBACK_STREAM_EXT                 = 1000028004,
	PERFORMANCE_QUERY_KHR                         = 1000116000,
	ACCELERATION_STRUCTURE_COMPACTED_SIZE_KHR     = 1000150000,
	ACCELERATION_STRUCTURE_SERIALIZATION_SIZE_KHR = 1000150001,
	ACCELERATION_STRUCTURE_COMPACTED_SIZE_NV      = 1000165000,
	PERFORMANCE_QUERY_INTEL                       = 1000210000,
	VIDEO_ENCODE_BITSTREAM_BUFFER_RANGE_KHR       = 1000299000,
	PRIMITIVES_GENERATED_EXT                      = 1000382000,
}

QueueFlags :: distinct bit_set[QueueFlag; Flags]
QueueFlag :: enum Flags {
	GRAPHICS         = 0,
	COMPUTE          = 1,
	TRANSFER         = 2,
	SPARSE_BINDING   = 3,
	PROTECTED        = 4,
	VIDEO_DECODE_KHR = 5,
	VIDEO_ENCODE_KHR = 6,
}

QueueGlobalPriorityKHR :: enum c.int {
	LOW          = 128,
	MEDIUM       = 256,
	HIGH         = 512,
	REALTIME     = 1024,
	LOW_EXT      = LOW,
	MEDIUM_EXT   = MEDIUM,
	HIGH_EXT     = HIGH,
	REALTIME_EXT = REALTIME,
}

RasterizationOrderAMD :: enum c.int {
	STRICT  = 0,
	RELAXED = 1,
}

RayTracingShaderGroupTypeKHR :: enum c.int {
	GENERAL                 = 0,
	TRIANGLES_HIT_GROUP     = 1,
	PROCEDURAL_HIT_GROUP    = 2,
	GENERAL_NV              = GENERAL,
	TRIANGLES_HIT_GROUP_NV  = TRIANGLES_HIT_GROUP,
	PROCEDURAL_HIT_GROUP_NV = PROCEDURAL_HIT_GROUP,
}

RenderPassCreateFlags :: distinct bit_set[RenderPassCreateFlag; Flags]
RenderPassCreateFlag :: enum Flags {
	TRANSFORM_QCOM = 1,
}

RenderingFlags :: distinct bit_set[RenderingFlag; Flags]
RenderingFlag :: enum Flags {
	CONTENTS_SECONDARY_COMMAND_BUFFERS     = 0,
	SUSPENDING                             = 1,
	RESUMING                               = 2,
	CONTENTS_SECONDARY_COMMAND_BUFFERS_KHR = CONTENTS_SECONDARY_COMMAND_BUFFERS,
	SUSPENDING_KHR                         = SUSPENDING,
	RESUMING_KHR                           = RESUMING,
}

ResolveModeFlags :: distinct bit_set[ResolveModeFlag; Flags]
ResolveModeFlag :: enum Flags {
	SAMPLE_ZERO     = 0,
	AVERAGE         = 1,
	MIN             = 2,
	MAX             = 3,
	SAMPLE_ZERO_KHR = SAMPLE_ZERO,
	AVERAGE_KHR     = AVERAGE,
	MIN_KHR         = MIN,
	MAX_KHR         = MAX,
}

ResolveModeFlags_NONE :: ResolveModeFlags{}


Result :: enum c.int {
	SUCCESS                                            = 0,
	NOT_READY                                          = 1,
	TIMEOUT                                            = 2,
	EVENT_SET                                          = 3,
	EVENT_RESET                                        = 4,
	INCOMPLETE                                         = 5,
	ERROR_OUT_OF_HOST_MEMORY                           = -1,
	ERROR_OUT_OF_DEVICE_MEMORY                         = -2,
	ERROR_INITIALIZATION_FAILED                        = -3,
	ERROR_DEVICE_LOST                                  = -4,
	ERROR_MEMORY_MAP_FAILED                            = -5,
	ERROR_LAYER_NOT_PRESENT                            = -6,
	ERROR_EXTENSION_NOT_PRESENT                        = -7,
	ERROR_FEATURE_NOT_PRESENT                          = -8,
	ERROR_INCOMPATIBLE_DRIVER                          = -9,
	ERROR_TOO_MANY_OBJECTS                             = -10,
	ERROR_FORMAT_NOT_SUPPORTED                         = -11,
	ERROR_FRAGMENTED_POOL                              = -12,
	ERROR_UNKNOWN                                      = -13,
	ERROR_OUT_OF_POOL_MEMORY                           = -1000069000,
	ERROR_INVALID_EXTERNAL_HANDLE                      = -1000072003,
	ERROR_FRAGMENTATION                                = -1000161000,
	ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS               = -1000257000,
	PIPELINE_COMPILE_REQUIRED                          = 1000297000,
	ERROR_SURFACE_LOST_KHR                             = -1000000000,
	ERROR_NATIVE_WINDOW_IN_USE_KHR                     = -1000000001,
	SUBOPTIMAL_KHR                                     = 1000001003,
	ERROR_OUT_OF_DATE_KHR                              = -1000001004,
	ERROR_INCOMPATIBLE_DISPLAY_KHR                     = -1000003001,
	ERROR_VALIDATION_FAILED_EXT                        = -1000011001,
	ERROR_INVALID_SHADER_NV                            = -1000012000,
	ERROR_INVALID_DRM_FORMAT_MODIFIER_PLANE_LAYOUT_EXT = -1000158000,
	ERROR_NOT_PERMITTED_KHR                            = -1000174001,
	ERROR_FULL_SCREEN_EXCLUSIVE_MODE_LOST_EXT          = -1000255000,
	THREAD_IDLE_KHR                                    = 1000268000,
	THREAD_DONE_KHR                                    = 1000268001,
	OPERATION_DEFERRED_KHR                             = 1000268002,
	OPERATION_NOT_DEFERRED_KHR                         = 1000268003,
	ERROR_OUT_OF_POOL_MEMORY_KHR                       = ERROR_OUT_OF_POOL_MEMORY,
	ERROR_INVALID_EXTERNAL_HANDLE_KHR                  = ERROR_INVALID_EXTERNAL_HANDLE,
	ERROR_FRAGMENTATION_EXT                            = ERROR_FRAGMENTATION,
	ERROR_NOT_PERMITTED_EXT                            = ERROR_NOT_PERMITTED_KHR,
	ERROR_INVALID_DEVICE_ADDRESS_EXT                   = ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS,
	ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS_KHR           = ERROR_INVALID_OPAQUE_CAPTURE_ADDRESS,
	PIPELINE_COMPILE_REQUIRED_EXT                      = PIPELINE_COMPILE_REQUIRED,
	ERROR_PIPELINE_COMPILE_REQUIRED_EXT                = PIPELINE_COMPILE_REQUIRED,
}

SampleCountFlags :: distinct bit_set[SampleCountFlag; Flags]
SampleCountFlag :: enum Flags {
	_1  = 0,
	_2  = 1,
	_4  = 2,
	_8  = 3,
	_16 = 4,
	_32 = 5,
	_64 = 6,
}

SamplerAddressMode :: enum c.int {
	REPEAT                   = 0,
	MIRRORED_REPEAT          = 1,
	CLAMP_TO_EDGE            = 2,
	CLAMP_TO_BORDER          = 3,
	MIRROR_CLAMP_TO_EDGE     = 4,
	MIRROR_CLAMP_TO_EDGE_KHR = MIRROR_CLAMP_TO_EDGE,
}

SamplerCreateFlags :: distinct bit_set[SamplerCreateFlag; Flags]
SamplerCreateFlag :: enum Flags {
	SUBSAMPLED_EXT                       = 0,
	SUBSAMPLED_COARSE_RECONSTRUCTION_EXT = 1,
}

SamplerMipmapMode :: enum c.int {
	NEAREST = 0,
	LINEAR  = 1,
}

SamplerReductionMode :: enum c.int {
	WEIGHTED_AVERAGE     = 0,
	MIN                  = 1,
	MAX                  = 2,
	WEIGHTED_AVERAGE_EXT = WEIGHTED_AVERAGE,
	MIN_EXT              = MIN,
	MAX_EXT              = MAX,
}

SamplerYcbcrModelConversion :: enum c.int {
	RGB_IDENTITY       = 0,
	YCBCR_IDENTITY     = 1,
	YCBCR_709          = 2,
	YCBCR_601          = 3,
	YCBCR_2020         = 4,
	RGB_IDENTITY_KHR   = RGB_IDENTITY,
	YCBCR_IDENTITY_KHR = YCBCR_IDENTITY,
	YCBCR_709_KHR      = YCBCR_709,
	YCBCR_601_KHR      = YCBCR_601,
	YCBCR_2020_KHR     = YCBCR_2020,
}

SamplerYcbcrRange :: enum c.int {
	ITU_FULL       = 0,
	ITU_NARROW     = 1,
	ITU_FULL_KHR   = ITU_FULL,
	ITU_NARROW_KHR = ITU_NARROW,
}

ScopeNV :: enum c.int {
	DEVICE       = 1,
	WORKGROUP    = 2,
	SUBGROUP     = 3,
	QUEUE_FAMILY = 5,
}

SemaphoreImportFlags :: distinct bit_set[SemaphoreImportFlag; Flags]
SemaphoreImportFlag :: enum Flags {
	TEMPORARY     = 0,
	TEMPORARY_KHR = TEMPORARY,
}

SemaphoreType :: enum c.int {
	BINARY       = 0,
	TIMELINE     = 1,
	BINARY_KHR   = BINARY,
	TIMELINE_KHR = TIMELINE,
}

SemaphoreWaitFlags :: distinct bit_set[SemaphoreWaitFlag; Flags]
SemaphoreWaitFlag :: enum Flags {
	ANY     = 0,
	ANY_KHR = ANY,
}

ShaderCorePropertiesFlagsAMD :: distinct bit_set[ShaderCorePropertiesFlagAMD; Flags]
ShaderCorePropertiesFlagAMD :: enum Flags {
}

ShaderFloatControlsIndependence :: enum c.int {
	_32_BIT_ONLY     = 0,
	ALL              = 1,
	NONE             = 2,
	_32_BIT_ONLY_KHR = _32_BIT_ONLY,
	ALL_KHR          = ALL,
}

ShaderGroupShaderKHR :: enum c.int {
	GENERAL      = 0,
	CLOSEST_HIT  = 1,
	ANY_HIT      = 2,
	INTERSECTION = 3,
}

ShaderInfoTypeAMD :: enum c.int {
	STATISTICS  = 0,
	BINARY      = 1,
	DISASSEMBLY = 2,
}

ShaderStageFlags :: distinct bit_set[ShaderStageFlag; Flags]
ShaderStageFlag :: enum Flags {
	VERTEX                  = 0,
	TESSELLATION_CONTROL    = 1,
	TESSELLATION_EVALUATION = 2,
	GEOMETRY                = 3,
	FRAGMENT                = 4,
	COMPUTE                 = 5,
	RAYGEN_KHR              = 8,
	ANY_HIT_KHR             = 9,
	CLOSEST_HIT_KHR         = 10,
	MISS_KHR                = 11,
	INTERSECTION_KHR        = 12,
	CALLABLE_KHR            = 13,
	TASK_NV                 = 6,
	MESH_NV                 = 7,
	SUBPASS_SHADING_HUAWEI  = 14,
	RAYGEN_NV               = RAYGEN_KHR,
	ANY_HIT_NV              = ANY_HIT_KHR,
	CLOSEST_HIT_NV          = CLOSEST_HIT_KHR,
	MISS_NV                 = MISS_KHR,
	INTERSECTION_NV         = INTERSECTION_KHR,
	CALLABLE_NV             = CALLABLE_KHR,
	_MAX                    = 31, // Needed for the *_ALL bit set
}

ShaderStageFlags_ALL_GRAPHICS :: ShaderStageFlags{.VERTEX, .TESSELLATION_CONTROL, .TESSELLATION_EVALUATION, .GEOMETRY, .FRAGMENT}
ShaderStageFlags_ALL :: ShaderStageFlags{.VERTEX, .TESSELLATION_CONTROL, .TESSELLATION_EVALUATION, .GEOMETRY, .FRAGMENT, .COMPUTE, .TASK_NV, .MESH_NV, .RAYGEN_KHR, .ANY_HIT_KHR, .CLOSEST_HIT_KHR, .MISS_KHR, .INTERSECTION_KHR, .CALLABLE_KHR, .SUBPASS_SHADING_HUAWEI, ShaderStageFlag(15), ShaderStageFlag(16), ShaderStageFlag(17), ShaderStageFlag(18), ShaderStageFlag(19), ShaderStageFlag(20), ShaderStageFlag(21), ShaderStageFlag(22), ShaderStageFlag(23), ShaderStageFlag(24), ShaderStageFlag(25), ShaderStageFlag(26), ShaderStageFlag(27), ShaderStageFlag(28), ShaderStageFlag(29), ShaderStageFlag(30)}


ShadingRatePaletteEntryNV :: enum c.int {
	NO_INVOCATIONS               = 0,
	_16_INVOCATIONS_PER_PIXEL    = 1,
	_8_INVOCATIONS_PER_PIXEL     = 2,
	_4_INVOCATIONS_PER_PIXEL     = 3,
	_2_INVOCATIONS_PER_PIXEL     = 4,
	_1_INVOCATION_PER_PIXEL      = 5,
	_1_INVOCATION_PER_2X1_PIXELS = 6,
	_1_INVOCATION_PER_1X2_PIXELS = 7,
	_1_INVOCATION_PER_2X2_PIXELS = 8,
	_1_INVOCATION_PER_4X2_PIXELS = 9,
	_1_INVOCATION_PER_2X4_PIXELS = 10,
	_1_INVOCATION_PER_4X4_PIXELS = 11,
}

SharingMode :: enum c.int {
	EXCLUSIVE  = 0,
	CONCURRENT = 1,
}

SparseImageFormatFlags :: distinct bit_set[SparseImageFormatFlag; Flags]
SparseImageFormatFlag :: enum Flags {
	SINGLE_MIPTAIL         = 0,
	ALIGNED_MIP_SIZE       = 1,
	NONSTANDARD_BLOCK_SIZE = 2,
}

SparseMemoryBindFlags :: distinct bit_set[SparseMemoryBindFlag; Flags]
SparseMemoryBindFlag :: enum Flags {
	METADATA = 0,
}

StencilFaceFlags :: distinct bit_set[StencilFaceFlag; Flags]
StencilFaceFlag :: enum Flags {
	FRONT                  = 0,
	BACK                   = 1,
}

StencilFaceFlags_FRONT_AND_BACK :: StencilFaceFlags{.FRONT, .BACK}


StencilOp :: enum c.int {
	KEEP                = 0,
	ZERO                = 1,
	REPLACE             = 2,
	INCREMENT_AND_CLAMP = 3,
	DECREMENT_AND_CLAMP = 4,
	INVERT              = 5,
	INCREMENT_AND_WRAP  = 6,
	DECREMENT_AND_WRAP  = 7,
}

StructureType :: enum c.int {
	APPLICATION_INFO                                                   = 0,
	INSTANCE_CREATE_INFO                                               = 1,
	DEVICE_QUEUE_CREATE_INFO                                           = 2,
	DEVICE_CREATE_INFO                                                 = 3,
	SUBMIT_INFO                                                        = 4,
	MEMORY_ALLOCATE_INFO                                               = 5,
	MAPPED_MEMORY_RANGE                                                = 6,
	BIND_SPARSE_INFO                                                   = 7,
	FENCE_CREATE_INFO                                                  = 8,
	SEMAPHORE_CREATE_INFO                                              = 9,
	EVENT_CREATE_INFO                                                  = 10,
	QUERY_POOL_CREATE_INFO                                             = 11,
	BUFFER_CREATE_INFO                                                 = 12,
	BUFFER_VIEW_CREATE_INFO                                            = 13,
	IMAGE_CREATE_INFO                                                  = 14,
	IMAGE_VIEW_CREATE_INFO                                             = 15,
	SHADER_MODULE_CREATE_INFO                                          = 16,
	PIPELINE_CACHE_CREATE_INFO                                         = 17,
	PIPELINE_SHADER_STAGE_CREATE_INFO                                  = 18,
	PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO                            = 19,
	PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO                          = 20,
	PIPELINE_TESSELLATION_STATE_CREATE_INFO                            = 21,
	PIPELINE_VIEWPORT_STATE_CREATE_INFO                                = 22,
	PIPELINE_RASTERIZATION_STATE_CREATE_INFO                           = 23,
	PIPELINE_MULTISAMPLE_STATE_CREATE_INFO                             = 24,
	PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO                           = 25,
	PIPELINE_COLOR_BLEND_STATE_CREATE_INFO                             = 26,
	PIPELINE_DYNAMIC_STATE_CREATE_INFO                                 = 27,
	GRAPHICS_PIPELINE_CREATE_INFO                                      = 28,
	COMPUTE_PIPELINE_CREATE_INFO                                       = 29,
	PIPELINE_LAYOUT_CREATE_INFO                                        = 30,
	SAMPLER_CREATE_INFO                                                = 31,
	DESCRIPTOR_SET_LAYOUT_CREATE_INFO                                  = 32,
	DESCRIPTOR_POOL_CREATE_INFO                                        = 33,
	DESCRIPTOR_SET_ALLOCATE_INFO                                       = 34,
	WRITE_DESCRIPTOR_SET                                               = 35,
	COPY_DESCRIPTOR_SET                                                = 36,
	FRAMEBUFFER_CREATE_INFO                                            = 37,
	RENDER_PASS_CREATE_INFO                                            = 38,
	COMMAND_POOL_CREATE_INFO                                           = 39,
	COMMAND_BUFFER_ALLOCATE_INFO                                       = 40,
	COMMAND_BUFFER_INHERITANCE_INFO                                    = 41,
	COMMAND_BUFFER_BEGIN_INFO                                          = 42,
	RENDER_PASS_BEGIN_INFO                                             = 43,
	BUFFER_MEMORY_BARRIER                                              = 44,
	IMAGE_MEMORY_BARRIER                                               = 45,
	MEMORY_BARRIER                                                     = 46,
	LOADER_INSTANCE_CREATE_INFO                                        = 47,
	LOADER_DEVICE_CREATE_INFO                                          = 48,
	PHYSICAL_DEVICE_SUBGROUP_PROPERTIES                                = 1000094000,
	BIND_BUFFER_MEMORY_INFO                                            = 1000157000,
	BIND_IMAGE_MEMORY_INFO                                             = 1000157001,
	PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES                             = 1000083000,
	MEMORY_DEDICATED_REQUIREMENTS                                      = 1000127000,
	MEMORY_DEDICATED_ALLOCATE_INFO                                     = 1000127001,
	MEMORY_ALLOCATE_FLAGS_INFO                                         = 1000060000,
	DEVICE_GROUP_RENDER_PASS_BEGIN_INFO                                = 1000060003,
	DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO                             = 1000060004,
	DEVICE_GROUP_SUBMIT_INFO                                           = 1000060005,
	DEVICE_GROUP_BIND_SPARSE_INFO                                      = 1000060006,
	BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO                               = 1000060013,
	BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO                                = 1000060014,
	PHYSICAL_DEVICE_GROUP_PROPERTIES                                   = 1000070000,
	DEVICE_GROUP_DEVICE_CREATE_INFO                                    = 1000070001,
	BUFFER_MEMORY_REQUIREMENTS_INFO_2                                  = 1000146000,
	IMAGE_MEMORY_REQUIREMENTS_INFO_2                                   = 1000146001,
	IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2                            = 1000146002,
	MEMORY_REQUIREMENTS_2                                              = 1000146003,
	SPARSE_IMAGE_MEMORY_REQUIREMENTS_2                                 = 1000146004,
	PHYSICAL_DEVICE_FEATURES_2                                         = 1000059000,
	PHYSICAL_DEVICE_PROPERTIES_2                                       = 1000059001,
	FORMAT_PROPERTIES_2                                                = 1000059002,
	IMAGE_FORMAT_PROPERTIES_2                                          = 1000059003,
	PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2                                = 1000059004,
	QUEUE_FAMILY_PROPERTIES_2                                          = 1000059005,
	PHYSICAL_DEVICE_MEMORY_PROPERTIES_2                                = 1000059006,
	SPARSE_IMAGE_FORMAT_PROPERTIES_2                                   = 1000059007,
	PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2                         = 1000059008,
	PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES                          = 1000117000,
	RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO                    = 1000117001,
	IMAGE_VIEW_USAGE_CREATE_INFO                                       = 1000117002,
	PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO              = 1000117003,
	RENDER_PASS_MULTIVIEW_CREATE_INFO                                  = 1000053000,
	PHYSICAL_DEVICE_MULTIVIEW_FEATURES                                 = 1000053001,
	PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES                               = 1000053002,
	PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES                         = 1000120000,
	PROTECTED_SUBMIT_INFO                                              = 1000145000,
	PHYSICAL_DEVICE_PROTECTED_MEMORY_FEATURES                          = 1000145001,
	PHYSICAL_DEVICE_PROTECTED_MEMORY_PROPERTIES                        = 1000145002,
	DEVICE_QUEUE_INFO_2                                                = 1000145003,
	SAMPLER_YCBCR_CONVERSION_CREATE_INFO                               = 1000156000,
	SAMPLER_YCBCR_CONVERSION_INFO                                      = 1000156001,
	BIND_IMAGE_PLANE_MEMORY_INFO                                       = 1000156002,
	IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO                               = 1000156003,
	PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES                  = 1000156004,
	SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES                   = 1000156005,
	DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO                             = 1000085000,
	PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO                         = 1000071000,
	EXTERNAL_IMAGE_FORMAT_PROPERTIES                                   = 1000071001,
	PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO                               = 1000071002,
	EXTERNAL_BUFFER_PROPERTIES                                         = 1000071003,
	PHYSICAL_DEVICE_ID_PROPERTIES                                      = 1000071004,
	EXTERNAL_MEMORY_BUFFER_CREATE_INFO                                 = 1000072000,
	EXTERNAL_MEMORY_IMAGE_CREATE_INFO                                  = 1000072001,
	EXPORT_MEMORY_ALLOCATE_INFO                                        = 1000072002,
	PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO                                = 1000112000,
	EXTERNAL_FENCE_PROPERTIES                                          = 1000112001,
	EXPORT_FENCE_CREATE_INFO                                           = 1000113000,
	EXPORT_SEMAPHORE_CREATE_INFO                                       = 1000077000,
	PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO                            = 1000076000,
	EXTERNAL_SEMAPHORE_PROPERTIES                                      = 1000076001,
	PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES                           = 1000168000,
	DESCRIPTOR_SET_LAYOUT_SUPPORT                                      = 1000168001,
	PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES                    = 1000063000,
	PHYSICAL_DEVICE_VULKAN_1_1_FEATURES                                = 49,
	PHYSICAL_DEVICE_VULKAN_1_1_PROPERTIES                              = 50,
	PHYSICAL_DEVICE_VULKAN_1_2_FEATURES                                = 51,
	PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES                              = 52,
	IMAGE_FORMAT_LIST_CREATE_INFO                                      = 1000147000,
	ATTACHMENT_DESCRIPTION_2                                           = 1000109000,
	ATTACHMENT_REFERENCE_2                                             = 1000109001,
	SUBPASS_DESCRIPTION_2                                              = 1000109002,
	SUBPASS_DEPENDENCY_2                                               = 1000109003,
	RENDER_PASS_CREATE_INFO_2                                          = 1000109004,
	SUBPASS_BEGIN_INFO                                                 = 1000109005,
	SUBPASS_END_INFO                                                   = 1000109006,
	PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES                              = 1000177000,
	PHYSICAL_DEVICE_DRIVER_PROPERTIES                                  = 1000196000,
	PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES                       = 1000180000,
	PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES                       = 1000082000,
	PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES                          = 1000197000,
	DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO                    = 1000161000,
	PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES                       = 1000161001,
	PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES                     = 1000161002,
	DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO             = 1000161003,
	DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT            = 1000161004,
	PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES                   = 1000199000,
	SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE                          = 1000199001,
	PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES                       = 1000221000,
	IMAGE_STENCIL_USAGE_CREATE_INFO                                    = 1000246000,
	PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES                   = 1000130000,
	SAMPLER_REDUCTION_MODE_CREATE_INFO                                 = 1000130001,
	PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES                       = 1000211000,
	PHYSICAL_DEVICE_IMAGELESS_FRAMEBUFFER_FEATURES                     = 1000108000,
	FRAMEBUFFER_ATTACHMENTS_CREATE_INFO                                = 1000108001,
	FRAMEBUFFER_ATTACHMENT_IMAGE_INFO                                  = 1000108002,
	RENDER_PASS_ATTACHMENT_BEGIN_INFO                                  = 1000108003,
	PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES            = 1000253000,
	PHYSICAL_DEVICE_SHADER_SUBGROUP_EXTENDED_TYPES_FEATURES            = 1000175000,
	PHYSICAL_DEVICE_SEPARATE_DEPTH_STENCIL_LAYOUTS_FEATURES            = 1000241000,
	ATTACHMENT_REFERENCE_STENCIL_LAYOUT                                = 1000241001,
	ATTACHMENT_DESCRIPTION_STENCIL_LAYOUT                              = 1000241002,
	PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES                          = 1000261000,
	PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES                        = 1000207000,
	PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_PROPERTIES                      = 1000207001,
	SEMAPHORE_TYPE_CREATE_INFO                                         = 1000207002,
	TIMELINE_SEMAPHORE_SUBMIT_INFO                                     = 1000207003,
	SEMAPHORE_WAIT_INFO                                                = 1000207004,
	SEMAPHORE_SIGNAL_INFO                                              = 1000207005,
	PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES                     = 1000257000,
	BUFFER_DEVICE_ADDRESS_INFO                                         = 1000244001,
	BUFFER_OPAQUE_CAPTURE_ADDRESS_CREATE_INFO                          = 1000257002,
	MEMORY_OPAQUE_CAPTURE_ADDRESS_ALLOCATE_INFO                        = 1000257003,
	DEVICE_MEMORY_OPAQUE_CAPTURE_ADDRESS_INFO                          = 1000257004,
	PHYSICAL_DEVICE_VULKAN_1_3_FEATURES                                = 53,
	PHYSICAL_DEVICE_VULKAN_1_3_PROPERTIES                              = 54,
	PIPELINE_CREATION_FEEDBACK_CREATE_INFO                             = 1000192000,
	PHYSICAL_DEVICE_SHADER_TERMINATE_INVOCATION_FEATURES               = 1000215000,
	PHYSICAL_DEVICE_TOOL_PROPERTIES                                    = 1000245000,
	PHYSICAL_DEVICE_SHADER_DEMOTE_TO_HELPER_INVOCATION_FEATURES        = 1000276000,
	PHYSICAL_DEVICE_PRIVATE_DATA_FEATURES                              = 1000295000,
	DEVICE_PRIVATE_DATA_CREATE_INFO                                    = 1000295001,
	PRIVATE_DATA_SLOT_CREATE_INFO                                      = 1000295002,
	PHYSICAL_DEVICE_PIPELINE_CREATION_CACHE_CONTROL_FEATURES           = 1000297000,
	MEMORY_BARRIER_2                                                   = 1000314000,
	BUFFER_MEMORY_BARRIER_2                                            = 1000314001,
	IMAGE_MEMORY_BARRIER_2                                             = 1000314002,
	DEPENDENCY_INFO                                                    = 1000314003,
	SUBMIT_INFO_2                                                      = 1000314004,
	SEMAPHORE_SUBMIT_INFO                                              = 1000314005,
	COMMAND_BUFFER_SUBMIT_INFO                                         = 1000314006,
	PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES                         = 1000314007,
	PHYSICAL_DEVICE_ZERO_INITIALIZE_WORKGROUP_MEMORY_FEATURES          = 1000325000,
	PHYSICAL_DEVICE_IMAGE_ROBUSTNESS_FEATURES                          = 1000335000,
	COPY_BUFFER_INFO_2                                                 = 1000337000,
	COPY_IMAGE_INFO_2                                                  = 1000337001,
	COPY_BUFFER_TO_IMAGE_INFO_2                                        = 1000337002,
	COPY_IMAGE_TO_BUFFER_INFO_2                                        = 1000337003,
	BLIT_IMAGE_INFO_2                                                  = 1000337004,
	RESOLVE_IMAGE_INFO_2                                               = 1000337005,
	BUFFER_COPY_2                                                      = 1000337006,
	IMAGE_COPY_2                                                       = 1000337007,
	IMAGE_BLIT_2                                                       = 1000337008,
	BUFFER_IMAGE_COPY_2                                                = 1000337009,
	IMAGE_RESOLVE_2                                                    = 1000337010,
	PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_PROPERTIES                   = 1000225000,
	PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO           = 1000225001,
	PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_FEATURES                     = 1000225002,
	PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES                      = 1000138000,
	PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES                    = 1000138001,
	WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK                          = 1000138002,
	DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO                   = 1000138003,
	PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTC_HDR_FEATURES              = 1000066000,
	RENDERING_INFO                                                     = 1000044000,
	RENDERING_ATTACHMENT_INFO                                          = 1000044001,
	PIPELINE_RENDERING_CREATE_INFO                                     = 1000044002,
	PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES                         = 1000044003,
	COMMAND_BUFFER_INHERITANCE_RENDERING_INFO                          = 1000044004,
	PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_FEATURES                = 1000280000,
	PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_PROPERTIES              = 1000280001,
	PHYSICAL_DEVICE_TEXEL_BUFFER_ALIGNMENT_PROPERTIES                  = 1000281001,
	FORMAT_PROPERTIES_3                                                = 1000360000,
	PHYSICAL_DEVICE_MAINTENANCE_4_FEATURES                             = 1000413000,
	PHYSICAL_DEVICE_MAINTENANCE_4_PROPERTIES                           = 1000413001,
	DEVICE_BUFFER_MEMORY_REQUIREMENTS                                  = 1000413002,
	DEVICE_IMAGE_MEMORY_REQUIREMENTS                                   = 1000413003,
	SWAPCHAIN_CREATE_INFO_KHR                                          = 1000001000,
	PRESENT_INFO_KHR                                                   = 1000001001,
	DEVICE_GROUP_PRESENT_CAPABILITIES_KHR                              = 1000060007,
	IMAGE_SWAPCHAIN_CREATE_INFO_KHR                                    = 1000060008,
	BIND_IMAGE_MEMORY_SWAPCHAIN_INFO_KHR                               = 1000060009,
	ACQUIRE_NEXT_IMAGE_INFO_KHR                                        = 1000060010,
	DEVICE_GROUP_PRESENT_INFO_KHR                                      = 1000060011,
	DEVICE_GROUP_SWAPCHAIN_CREATE_INFO_KHR                             = 1000060012,
	DISPLAY_MODE_CREATE_INFO_KHR                                       = 1000002000,
	DISPLAY_SURFACE_CREATE_INFO_KHR                                    = 1000002001,
	DISPLAY_PRESENT_INFO_KHR                                           = 1000003000,
	XLIB_SURFACE_CREATE_INFO_KHR                                       = 1000004000,
	XCB_SURFACE_CREATE_INFO_KHR                                        = 1000005000,
	WAYLAND_SURFACE_CREATE_INFO_KHR                                    = 1000006000,
	ANDROID_SURFACE_CREATE_INFO_KHR                                    = 1000008000,
	WIN32_SURFACE_CREATE_INFO_KHR                                      = 1000009000,
	DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT                              = 1000011000,
	PIPELINE_RASTERIZATION_STATE_RASTERIZATION_ORDER_AMD               = 1000018000,
	DEBUG_MARKER_OBJECT_NAME_INFO_EXT                                  = 1000022000,
	DEBUG_MARKER_OBJECT_TAG_INFO_EXT                                   = 1000022001,
	DEBUG_MARKER_MARKER_INFO_EXT                                       = 1000022002,
	VIDEO_PROFILE_KHR                                                  = 1000023000,
	VIDEO_CAPABILITIES_KHR                                             = 1000023001,
	VIDEO_PICTURE_RESOURCE_KHR                                         = 1000023002,
	VIDEO_GET_MEMORY_PROPERTIES_KHR                                    = 1000023003,
	VIDEO_BIND_MEMORY_KHR                                              = 1000023004,
	VIDEO_SESSION_CREATE_INFO_KHR                                      = 1000023005,
	VIDEO_SESSION_PARAMETERS_CREATE_INFO_KHR                           = 1000023006,
	VIDEO_SESSION_PARAMETERS_UPDATE_INFO_KHR                           = 1000023007,
	VIDEO_BEGIN_CODING_INFO_KHR                                        = 1000023008,
	VIDEO_END_CODING_INFO_KHR                                          = 1000023009,
	VIDEO_CODING_CONTROL_INFO_KHR                                      = 1000023010,
	VIDEO_REFERENCE_SLOT_KHR                                           = 1000023011,
	VIDEO_QUEUE_FAMILY_PROPERTIES_2_KHR                                = 1000023012,
	VIDEO_PROFILES_KHR                                                 = 1000023013,
	PHYSICAL_DEVICE_VIDEO_FORMAT_INFO_KHR                              = 1000023014,
	VIDEO_FORMAT_PROPERTIES_KHR                                        = 1000023015,
	QUEUE_FAMILY_QUERY_RESULT_STATUS_PROPERTIES_2_KHR                  = 1000023016,
	VIDEO_DECODE_INFO_KHR                                              = 1000024000,
	VIDEO_DECODE_CAPABILITIES_KHR                                      = 1000024001,
	DEDICATED_ALLOCATION_IMAGE_CREATE_INFO_NV                          = 1000026000,
	DEDICATED_ALLOCATION_BUFFER_CREATE_INFO_NV                         = 1000026001,
	DEDICATED_ALLOCATION_MEMORY_ALLOCATE_INFO_NV                       = 1000026002,
	PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_FEATURES_EXT                    = 1000028000,
	PHYSICAL_DEVICE_TRANSFORM_FEEDBACK_PROPERTIES_EXT                  = 1000028001,
	PIPELINE_RASTERIZATION_STATE_STREAM_CREATE_INFO_EXT                = 1000028002,
	CU_MODULE_CREATE_INFO_NVX                                          = 1000029000,
	CU_FUNCTION_CREATE_INFO_NVX                                        = 1000029001,
	CU_LAUNCH_INFO_NVX                                                 = 1000029002,
	IMAGE_VIEW_HANDLE_INFO_NVX                                         = 1000030000,
	IMAGE_VIEW_ADDRESS_PROPERTIES_NVX                                  = 1000030001,
	VIDEO_ENCODE_H264_CAPABILITIES_EXT                                 = 1000038000,
	VIDEO_ENCODE_H264_SESSION_PARAMETERS_CREATE_INFO_EXT               = 1000038001,
	VIDEO_ENCODE_H264_SESSION_PARAMETERS_ADD_INFO_EXT                  = 1000038002,
	VIDEO_ENCODE_H264_VCL_FRAME_INFO_EXT                               = 1000038003,
	VIDEO_ENCODE_H264_DPB_SLOT_INFO_EXT                                = 1000038004,
	VIDEO_ENCODE_H264_NALU_SLICE_EXT                                   = 1000038005,
	VIDEO_ENCODE_H264_EMIT_PICTURE_PARAMETERS_EXT                      = 1000038006,
	VIDEO_ENCODE_H264_PROFILE_EXT                                      = 1000038007,
	VIDEO_ENCODE_H264_RATE_CONTROL_INFO_EXT                            = 1000038008,
	VIDEO_ENCODE_H264_RATE_CONTROL_LAYER_INFO_EXT                      = 1000038009,
	VIDEO_ENCODE_H264_REFERENCE_LISTS_EXT                              = 1000038010,
	VIDEO_ENCODE_H265_CAPABILITIES_EXT                                 = 1000039000,
	VIDEO_ENCODE_H265_SESSION_PARAMETERS_CREATE_INFO_EXT               = 1000039001,
	VIDEO_ENCODE_H265_SESSION_PARAMETERS_ADD_INFO_EXT                  = 1000039002,
	VIDEO_ENCODE_H265_VCL_FRAME_INFO_EXT                               = 1000039003,
	VIDEO_ENCODE_H265_DPB_SLOT_INFO_EXT                                = 1000039004,
	VIDEO_ENCODE_H265_NALU_SLICE_SEGMENT_EXT                           = 1000039005,
	VIDEO_ENCODE_H265_EMIT_PICTURE_PARAMETERS_EXT                      = 1000039006,
	VIDEO_ENCODE_H265_PROFILE_EXT                                      = 1000039007,
	VIDEO_ENCODE_H265_REFERENCE_LISTS_EXT                              = 1000039008,
	VIDEO_ENCODE_H265_RATE_CONTROL_INFO_EXT                            = 1000039009,
	VIDEO_ENCODE_H265_RATE_CONTROL_LAYER_INFO_EXT                      = 1000039010,
	VIDEO_DECODE_H264_CAPABILITIES_EXT                                 = 1000040000,
	VIDEO_DECODE_H264_PICTURE_INFO_EXT                                 = 1000040001,
	VIDEO_DECODE_H264_MVC_EXT                                          = 1000040002,
	VIDEO_DECODE_H264_PROFILE_EXT                                      = 1000040003,
	VIDEO_DECODE_H264_SESSION_PARAMETERS_CREATE_INFO_EXT               = 1000040004,
	VIDEO_DECODE_H264_SESSION_PARAMETERS_ADD_INFO_EXT                  = 1000040005,
	VIDEO_DECODE_H264_DPB_SLOT_INFO_EXT                                = 1000040006,
	TEXTURE_LOD_GATHER_FORMAT_PROPERTIES_AMD                           = 1000041000,
	RENDERING_FRAGMENT_SHADING_RATE_ATTACHMENT_INFO_KHR                = 1000044006,
	RENDERING_FRAGMENT_DENSITY_MAP_ATTACHMENT_INFO_EXT                 = 1000044007,
	ATTACHMENT_SAMPLE_COUNT_INFO_AMD                                   = 1000044008,
	MULTIVIEW_PER_VIEW_ATTRIBUTES_INFO_NVX                             = 1000044009,
	STREAM_DESCRIPTOR_SURFACE_CREATE_INFO_GGP                          = 1000049000,
	PHYSICAL_DEVICE_CORNER_SAMPLED_IMAGE_FEATURES_NV                   = 1000050000,
	EXTERNAL_MEMORY_IMAGE_CREATE_INFO_NV                               = 1000056000,
	EXPORT_MEMORY_ALLOCATE_INFO_NV                                     = 1000056001,
	IMPORT_MEMORY_WIN32_HANDLE_INFO_NV                                 = 1000057000,
	EXPORT_MEMORY_WIN32_HANDLE_INFO_NV                                 = 1000057001,
	WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_NV                          = 1000058000,
	VALIDATION_FLAGS_EXT                                               = 1000061000,
	VI_SURFACE_CREATE_INFO_NN                                          = 1000062000,
	IMAGE_VIEW_ASTC_DECODE_MODE_EXT                                    = 1000067000,
	PHYSICAL_DEVICE_ASTC_DECODE_FEATURES_EXT                           = 1000067001,
	IMPORT_MEMORY_WIN32_HANDLE_INFO_KHR                                = 1000073000,
	EXPORT_MEMORY_WIN32_HANDLE_INFO_KHR                                = 1000073001,
	MEMORY_WIN32_HANDLE_PROPERTIES_KHR                                 = 1000073002,
	MEMORY_GET_WIN32_HANDLE_INFO_KHR                                   = 1000073003,
	IMPORT_MEMORY_FD_INFO_KHR                                          = 1000074000,
	MEMORY_FD_PROPERTIES_KHR                                           = 1000074001,
	MEMORY_GET_FD_INFO_KHR                                             = 1000074002,
	WIN32_KEYED_MUTEX_ACQUIRE_RELEASE_INFO_KHR                         = 1000075000,
	IMPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR                             = 1000078000,
	EXPORT_SEMAPHORE_WIN32_HANDLE_INFO_KHR                             = 1000078001,
	D3D12_FENCE_SUBMIT_INFO_KHR                                        = 1000078002,
	SEMAPHORE_GET_WIN32_HANDLE_INFO_KHR                                = 1000078003,
	IMPORT_SEMAPHORE_FD_INFO_KHR                                       = 1000079000,
	SEMAPHORE_GET_FD_INFO_KHR                                          = 1000079001,
	PHYSICAL_DEVICE_PUSH_DESCRIPTOR_PROPERTIES_KHR                     = 1000080000,
	COMMAND_BUFFER_INHERITANCE_CONDITIONAL_RENDERING_INFO_EXT          = 1000081000,
	PHYSICAL_DEVICE_CONDITIONAL_RENDERING_FEATURES_EXT                 = 1000081001,
	CONDITIONAL_RENDERING_BEGIN_INFO_EXT                               = 1000081002,
	PRESENT_REGIONS_KHR                                                = 1000084000,
	PIPELINE_VIEWPORT_W_SCALING_STATE_CREATE_INFO_NV                   = 1000087000,
	SURFACE_CAPABILITIES_2_EXT                                         = 1000090000,
	DISPLAY_POWER_INFO_EXT                                             = 1000091000,
	DEVICE_EVENT_INFO_EXT                                              = 1000091001,
	DISPLAY_EVENT_INFO_EXT                                             = 1000091002,
	SWAPCHAIN_COUNTER_CREATE_INFO_EXT                                  = 1000091003,
	PRESENT_TIMES_INFO_GOOGLE                                          = 1000092000,
	PHYSICAL_DEVICE_MULTIVIEW_PER_VIEW_ATTRIBUTES_PROPERTIES_NVX       = 1000097000,
	PIPELINE_VIEWPORT_SWIZZLE_STATE_CREATE_INFO_NV                     = 1000098000,
	PHYSICAL_DEVICE_DISCARD_RECTANGLE_PROPERTIES_EXT                   = 1000099000,
	PIPELINE_DISCARD_RECTANGLE_STATE_CREATE_INFO_EXT                   = 1000099001,
	PHYSICAL_DEVICE_CONSERVATIVE_RASTERIZATION_PROPERTIES_EXT          = 1000101000,
	PIPELINE_RASTERIZATION_CONSERVATIVE_STATE_CREATE_INFO_EXT          = 1000101001,
	PHYSICAL_DEVICE_DEPTH_CLIP_ENABLE_FEATURES_EXT                     = 1000102000,
	PIPELINE_RASTERIZATION_DEPTH_CLIP_STATE_CREATE_INFO_EXT            = 1000102001,
	HDR_METADATA_EXT                                                   = 1000105000,
	SHARED_PRESENT_SURFACE_CAPABILITIES_KHR                            = 1000111000,
	IMPORT_FENCE_WIN32_HANDLE_INFO_KHR                                 = 1000114000,
	EXPORT_FENCE_WIN32_HANDLE_INFO_KHR                                 = 1000114001,
	FENCE_GET_WIN32_HANDLE_INFO_KHR                                    = 1000114002,
	IMPORT_FENCE_FD_INFO_KHR                                           = 1000115000,
	FENCE_GET_FD_INFO_KHR                                              = 1000115001,
	PHYSICAL_DEVICE_PERFORMANCE_QUERY_FEATURES_KHR                     = 1000116000,
	PHYSICAL_DEVICE_PERFORMANCE_QUERY_PROPERTIES_KHR                   = 1000116001,
	QUERY_POOL_PERFORMANCE_CREATE_INFO_KHR                             = 1000116002,
	PERFORMANCE_QUERY_SUBMIT_INFO_KHR                                  = 1000116003,
	ACQUIRE_PROFILING_LOCK_INFO_KHR                                    = 1000116004,
	PERFORMANCE_COUNTER_KHR                                            = 1000116005,
	PERFORMANCE_COUNTER_DESCRIPTION_KHR                                = 1000116006,
	PHYSICAL_DEVICE_SURFACE_INFO_2_KHR                                 = 1000119000,
	SURFACE_CAPABILITIES_2_KHR                                         = 1000119001,
	SURFACE_FORMAT_2_KHR                                               = 1000119002,
	DISPLAY_PROPERTIES_2_KHR                                           = 1000121000,
	DISPLAY_PLANE_PROPERTIES_2_KHR                                     = 1000121001,
	DISPLAY_MODE_PROPERTIES_2_KHR                                      = 1000121002,
	DISPLAY_PLANE_INFO_2_KHR                                           = 1000121003,
	DISPLAY_PLANE_CAPABILITIES_2_KHR                                   = 1000121004,
	IOS_SURFACE_CREATE_INFO_MVK                                        = 1000122000,
	MACOS_SURFACE_CREATE_INFO_MVK                                      = 1000123000,
	DEBUG_UTILS_OBJECT_NAME_INFO_EXT                                   = 1000128000,
	DEBUG_UTILS_OBJECT_TAG_INFO_EXT                                    = 1000128001,
	DEBUG_UTILS_LABEL_EXT                                              = 1000128002,
	DEBUG_UTILS_MESSENGER_CALLBACK_DATA_EXT                            = 1000128003,
	DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT                              = 1000128004,
	ANDROID_HARDWARE_BUFFER_USAGE_ANDROID                              = 1000129000,
	ANDROID_HARDWARE_BUFFER_PROPERTIES_ANDROID                         = 1000129001,
	ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_ANDROID                  = 1000129002,
	IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID                        = 1000129003,
	MEMORY_GET_ANDROID_HARDWARE_BUFFER_INFO_ANDROID                    = 1000129004,
	EXTERNAL_FORMAT_ANDROID                                            = 1000129005,
	ANDROID_HARDWARE_BUFFER_FORMAT_PROPERTIES_2_ANDROID                = 1000129006,
	SAMPLE_LOCATIONS_INFO_EXT                                          = 1000143000,
	RENDER_PASS_SAMPLE_LOCATIONS_BEGIN_INFO_EXT                        = 1000143001,
	PIPELINE_SAMPLE_LOCATIONS_STATE_CREATE_INFO_EXT                    = 1000143002,
	PHYSICAL_DEVICE_SAMPLE_LOCATIONS_PROPERTIES_EXT                    = 1000143003,
	MULTISAMPLE_PROPERTIES_EXT                                         = 1000143004,
	PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_FEATURES_EXT              = 1000148000,
	PHYSICAL_DEVICE_BLEND_OPERATION_ADVANCED_PROPERTIES_EXT            = 1000148001,
	PIPELINE_COLOR_BLEND_ADVANCED_STATE_CREATE_INFO_EXT                = 1000148002,
	PIPELINE_COVERAGE_TO_COLOR_STATE_CREATE_INFO_NV                    = 1000149000,
	WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_KHR                    = 1000150007,
	ACCELERATION_STRUCTURE_BUILD_GEOMETRY_INFO_KHR                     = 1000150000,
	ACCELERATION_STRUCTURE_DEVICE_ADDRESS_INFO_KHR                     = 1000150002,
	ACCELERATION_STRUCTURE_GEOMETRY_AABBS_DATA_KHR                     = 1000150003,
	ACCELERATION_STRUCTURE_GEOMETRY_INSTANCES_DATA_KHR                 = 1000150004,
	ACCELERATION_STRUCTURE_GEOMETRY_TRIANGLES_DATA_KHR                 = 1000150005,
	ACCELERATION_STRUCTURE_GEOMETRY_KHR                                = 1000150006,
	ACCELERATION_STRUCTURE_VERSION_INFO_KHR                            = 1000150009,
	COPY_ACCELERATION_STRUCTURE_INFO_KHR                               = 1000150010,
	COPY_ACCELERATION_STRUCTURE_TO_MEMORY_INFO_KHR                     = 1000150011,
	COPY_MEMORY_TO_ACCELERATION_STRUCTURE_INFO_KHR                     = 1000150012,
	PHYSICAL_DEVICE_ACCELERATION_STRUCTURE_FEATURES_KHR                = 1000150013,
	PHYSICAL_DEVICE_ACCELERATION_STRUCTURE_PROPERTIES_KHR              = 1000150014,
	ACCELERATION_STRUCTURE_CREATE_INFO_KHR                             = 1000150017,
	ACCELERATION_STRUCTURE_BUILD_SIZES_INFO_KHR                        = 1000150020,
	PHYSICAL_DEVICE_RAY_TRACING_PIPELINE_FEATURES_KHR                  = 1000347000,
	PHYSICAL_DEVICE_RAY_TRACING_PIPELINE_PROPERTIES_KHR                = 1000347001,
	RAY_TRACING_PIPELINE_CREATE_INFO_KHR                               = 1000150015,
	RAY_TRACING_SHADER_GROUP_CREATE_INFO_KHR                           = 1000150016,
	RAY_TRACING_PIPELINE_INTERFACE_CREATE_INFO_KHR                     = 1000150018,
	PHYSICAL_DEVICE_RAY_QUERY_FEATURES_KHR                             = 1000348013,
	PIPELINE_COVERAGE_MODULATION_STATE_CREATE_INFO_NV                  = 1000152000,
	PHYSICAL_DEVICE_SHADER_SM_BUILTINS_FEATURES_NV                     = 1000154000,
	PHYSICAL_DEVICE_SHADER_SM_BUILTINS_PROPERTIES_NV                   = 1000154001,
	DRM_FORMAT_MODIFIER_PROPERTIES_LIST_EXT                            = 1000158000,
	PHYSICAL_DEVICE_IMAGE_DRM_FORMAT_MODIFIER_INFO_EXT                 = 1000158002,
	IMAGE_DRM_FORMAT_MODIFIER_LIST_CREATE_INFO_EXT                     = 1000158003,
	IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT                 = 1000158004,
	IMAGE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT                           = 1000158005,
	DRM_FORMAT_MODIFIER_PROPERTIES_LIST_2_EXT                          = 1000158006,
	VALIDATION_CACHE_CREATE_INFO_EXT                                   = 1000160000,
	SHADER_MODULE_VALIDATION_CACHE_CREATE_INFO_EXT                     = 1000160001,
	PHYSICAL_DEVICE_PORTABILITY_SUBSET_FEATURES_KHR                    = 1000163000,
	PHYSICAL_DEVICE_PORTABILITY_SUBSET_PROPERTIES_KHR                  = 1000163001,
	PIPELINE_VIEWPORT_SHADING_RATE_IMAGE_STATE_CREATE_INFO_NV          = 1000164000,
	PHYSICAL_DEVICE_SHADING_RATE_IMAGE_FEATURES_NV                     = 1000164001,
	PHYSICAL_DEVICE_SHADING_RATE_IMAGE_PROPERTIES_NV                   = 1000164002,
	PIPELINE_VIEWPORT_COARSE_SAMPLE_ORDER_STATE_CREATE_INFO_NV         = 1000164005,
	RAY_TRACING_PIPELINE_CREATE_INFO_NV                                = 1000165000,
	ACCELERATION_STRUCTURE_CREATE_INFO_NV                              = 1000165001,
	GEOMETRY_NV                                                        = 1000165003,
	GEOMETRY_TRIANGLES_NV                                              = 1000165004,
	GEOMETRY_AABB_NV                                                   = 1000165005,
	BIND_ACCELERATION_STRUCTURE_MEMORY_INFO_NV                         = 1000165006,
	WRITE_DESCRIPTOR_SET_ACCELERATION_STRUCTURE_NV                     = 1000165007,
	ACCELERATION_STRUCTURE_MEMORY_REQUIREMENTS_INFO_NV                 = 1000165008,
	PHYSICAL_DEVICE_RAY_TRACING_PROPERTIES_NV                          = 1000165009,
	RAY_TRACING_SHADER_GROUP_CREATE_INFO_NV                            = 1000165011,
	ACCELERATION_STRUCTURE_INFO_NV                                     = 1000165012,
	PHYSICAL_DEVICE_REPRESENTATIVE_FRAGMENT_TEST_FEATURES_NV           = 1000166000,
	PIPELINE_REPRESENTATIVE_FRAGMENT_TEST_STATE_CREATE_INFO_NV         = 1000166001,
	PHYSICAL_DEVICE_IMAGE_VIEW_IMAGE_FORMAT_INFO_EXT                   = 1000170000,
	FILTER_CUBIC_IMAGE_VIEW_IMAGE_FORMAT_PROPERTIES_EXT                = 1000170001,
	IMPORT_MEMORY_HOST_POINTER_INFO_EXT                                = 1000178000,
	MEMORY_HOST_POINTER_PROPERTIES_EXT                                 = 1000178001,
	PHYSICAL_DEVICE_EXTERNAL_MEMORY_HOST_PROPERTIES_EXT                = 1000178002,
	PHYSICAL_DEVICE_SHADER_CLOCK_FEATURES_KHR                          = 1000181000,
	PIPELINE_COMPILER_CONTROL_CREATE_INFO_AMD                          = 1000183000,
	CALIBRATED_TIMESTAMP_INFO_EXT                                      = 1000184000,
	PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_AMD                         = 1000185000,
	VIDEO_DECODE_H265_CAPABILITIES_EXT                                 = 1000187000,
	VIDEO_DECODE_H265_SESSION_PARAMETERS_CREATE_INFO_EXT               = 1000187001,
	VIDEO_DECODE_H265_SESSION_PARAMETERS_ADD_INFO_EXT                  = 1000187002,
	VIDEO_DECODE_H265_PROFILE_EXT                                      = 1000187003,
	VIDEO_DECODE_H265_PICTURE_INFO_EXT                                 = 1000187004,
	VIDEO_DECODE_H265_DPB_SLOT_INFO_EXT                                = 1000187005,
	DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO_KHR                       = 1000174000,
	PHYSICAL_DEVICE_GLOBAL_PRIORITY_QUERY_FEATURES_KHR                 = 1000388000,
	QUEUE_FAMILY_GLOBAL_PRIORITY_PROPERTIES_KHR                        = 1000388001,
	DEVICE_MEMORY_OVERALLOCATION_CREATE_INFO_AMD                       = 1000189000,
	PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_PROPERTIES_EXT            = 1000190000,
	PIPELINE_VERTEX_INPUT_DIVISOR_STATE_CREATE_INFO_EXT                = 1000190001,
	PHYSICAL_DEVICE_VERTEX_ATTRIBUTE_DIVISOR_FEATURES_EXT              = 1000190002,
	PRESENT_FRAME_TOKEN_GGP                                            = 1000191000,
	PHYSICAL_DEVICE_COMPUTE_SHADER_DERIVATIVES_FEATURES_NV             = 1000201000,
	PHYSICAL_DEVICE_MESH_SHADER_FEATURES_NV                            = 1000202000,
	PHYSICAL_DEVICE_MESH_SHADER_PROPERTIES_NV                          = 1000202001,
	PHYSICAL_DEVICE_FRAGMENT_SHADER_BARYCENTRIC_FEATURES_NV            = 1000203000,
	PHYSICAL_DEVICE_SHADER_IMAGE_FOOTPRINT_FEATURES_NV                 = 1000204000,
	PIPELINE_VIEWPORT_EXCLUSIVE_SCISSOR_STATE_CREATE_INFO_NV           = 1000205000,
	PHYSICAL_DEVICE_EXCLUSIVE_SCISSOR_FEATURES_NV                      = 1000205002,
	CHECKPOINT_DATA_NV                                                 = 1000206000,
	QUEUE_FAMILY_CHECKPOINT_PROPERTIES_NV                              = 1000206001,
	PHYSICAL_DEVICE_SHADER_INTEGER_FUNCTIONS_2_FEATURES_INTEL          = 1000209000,
	QUERY_POOL_PERFORMANCE_QUERY_CREATE_INFO_INTEL                     = 1000210000,
	INITIALIZE_PERFORMANCE_API_INFO_INTEL                              = 1000210001,
	PERFORMANCE_MARKER_INFO_INTEL                                      = 1000210002,
	PERFORMANCE_STREAM_MARKER_INFO_INTEL                               = 1000210003,
	PERFORMANCE_OVERRIDE_INFO_INTEL                                    = 1000210004,
	PERFORMANCE_CONFIGURATION_ACQUIRE_INFO_INTEL                       = 1000210005,
	PHYSICAL_DEVICE_PCI_BUS_INFO_PROPERTIES_EXT                        = 1000212000,
	DISPLAY_NATIVE_HDR_SURFACE_CAPABILITIES_AMD                        = 1000213000,
	SWAPCHAIN_DISPLAY_NATIVE_HDR_CREATE_INFO_AMD                       = 1000213001,
	IMAGEPIPE_SURFACE_CREATE_INFO_FUCHSIA                              = 1000214000,
	METAL_SURFACE_CREATE_INFO_EXT                                      = 1000217000,
	PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_FEATURES_EXT                  = 1000218000,
	PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_PROPERTIES_EXT                = 1000218001,
	RENDER_PASS_FRAGMENT_DENSITY_MAP_CREATE_INFO_EXT                   = 1000218002,
	FRAGMENT_SHADING_RATE_ATTACHMENT_INFO_KHR                          = 1000226000,
	PIPELINE_FRAGMENT_SHADING_RATE_STATE_CREATE_INFO_KHR               = 1000226001,
	PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_PROPERTIES_KHR               = 1000226002,
	PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_FEATURES_KHR                 = 1000226003,
	PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_KHR                          = 1000226004,
	PHYSICAL_DEVICE_SHADER_CORE_PROPERTIES_2_AMD                       = 1000227000,
	PHYSICAL_DEVICE_COHERENT_MEMORY_FEATURES_AMD                       = 1000229000,
	PHYSICAL_DEVICE_SHADER_IMAGE_ATOMIC_INT64_FEATURES_EXT             = 1000234000,
	PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT                       = 1000237000,
	PHYSICAL_DEVICE_MEMORY_PRIORITY_FEATURES_EXT                       = 1000238000,
	MEMORY_PRIORITY_ALLOCATE_INFO_EXT                                  = 1000238001,
	SURFACE_PROTECTED_CAPABILITIES_KHR                                 = 1000239000,
	PHYSICAL_DEVICE_DEDICATED_ALLOCATION_IMAGE_ALIASING_FEATURES_NV    = 1000240000,
	PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT                 = 1000244000,
	BUFFER_DEVICE_ADDRESS_CREATE_INFO_EXT                              = 1000244002,
	VALIDATION_FEATURES_EXT                                            = 1000247000,
	PHYSICAL_DEVICE_PRESENT_WAIT_FEATURES_KHR                          = 1000248000,
	PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_NV                     = 1000249000,
	COOPERATIVE_MATRIX_PROPERTIES_NV                                   = 1000249001,
	PHYSICAL_DEVICE_COOPERATIVE_MATRIX_PROPERTIES_NV                   = 1000249002,
	PHYSICAL_DEVICE_COVERAGE_REDUCTION_MODE_FEATURES_NV                = 1000250000,
	PIPELINE_COVERAGE_REDUCTION_STATE_CREATE_INFO_NV                   = 1000250001,
	FRAMEBUFFER_MIXED_SAMPLES_COMBINATION_NV                           = 1000250002,
	PHYSICAL_DEVICE_FRAGMENT_SHADER_INTERLOCK_FEATURES_EXT             = 1000251000,
	PHYSICAL_DEVICE_YCBCR_IMAGE_ARRAYS_FEATURES_EXT                    = 1000252000,
	PHYSICAL_DEVICE_PROVOKING_VERTEX_FEATURES_EXT                      = 1000254000,
	PIPELINE_RASTERIZATION_PROVOKING_VERTEX_STATE_CREATE_INFO_EXT      = 1000254001,
	PHYSICAL_DEVICE_PROVOKING_VERTEX_PROPERTIES_EXT                    = 1000254002,
	SURFACE_FULL_SCREEN_EXCLUSIVE_INFO_EXT                             = 1000255000,
	SURFACE_CAPABILITIES_FULL_SCREEN_EXCLUSIVE_EXT                     = 1000255002,
	SURFACE_FULL_SCREEN_EXCLUSIVE_WIN32_INFO_EXT                       = 1000255001,
	HEADLESS_SURFACE_CREATE_INFO_EXT                                   = 1000256000,
	PHYSICAL_DEVICE_LINE_RASTERIZATION_FEATURES_EXT                    = 1000259000,
	PIPELINE_RASTERIZATION_LINE_STATE_CREATE_INFO_EXT                  = 1000259001,
	PHYSICAL_DEVICE_LINE_RASTERIZATION_PROPERTIES_EXT                  = 1000259002,
	PHYSICAL_DEVICE_SHADER_ATOMIC_FLOAT_FEATURES_EXT                   = 1000260000,
	PHYSICAL_DEVICE_INDEX_TYPE_UINT8_FEATURES_EXT                      = 1000265000,
	PHYSICAL_DEVICE_EXTENDED_DYNAMIC_STATE_FEATURES_EXT                = 1000267000,
	PHYSICAL_DEVICE_PIPELINE_EXECUTABLE_PROPERTIES_FEATURES_KHR        = 1000269000,
	PIPELINE_INFO_KHR                                                  = 1000269001,
	PIPELINE_EXECUTABLE_PROPERTIES_KHR                                 = 1000269002,
	PIPELINE_EXECUTABLE_INFO_KHR                                       = 1000269003,
	PIPELINE_EXECUTABLE_STATISTIC_KHR                                  = 1000269004,
	PIPELINE_EXECUTABLE_INTERNAL_REPRESENTATION_KHR                    = 1000269005,
	PHYSICAL_DEVICE_SHADER_ATOMIC_FLOAT_2_FEATURES_EXT                 = 1000273000,
	PHYSICAL_DEVICE_DEVICE_GENERATED_COMMANDS_PROPERTIES_NV            = 1000277000,
	GRAPHICS_SHADER_GROUP_CREATE_INFO_NV                               = 1000277001,
	GRAPHICS_PIPELINE_SHADER_GROUPS_CREATE_INFO_NV                     = 1000277002,
	INDIRECT_COMMANDS_LAYOUT_TOKEN_NV                                  = 1000277003,
	INDIRECT_COMMANDS_LAYOUT_CREATE_INFO_NV                            = 1000277004,
	GENERATED_COMMANDS_INFO_NV                                         = 1000277005,
	GENERATED_COMMANDS_MEMORY_REQUIREMENTS_INFO_NV                     = 1000277006,
	PHYSICAL_DEVICE_DEVICE_GENERATED_COMMANDS_FEATURES_NV              = 1000277007,
	PHYSICAL_DEVICE_INHERITED_VIEWPORT_SCISSOR_FEATURES_NV             = 1000278000,
	COMMAND_BUFFER_INHERITANCE_VIEWPORT_SCISSOR_INFO_NV                = 1000278001,
	PHYSICAL_DEVICE_TEXEL_BUFFER_ALIGNMENT_FEATURES_EXT                = 1000281000,
	COMMAND_BUFFER_INHERITANCE_RENDER_PASS_TRANSFORM_INFO_QCOM         = 1000282000,
	RENDER_PASS_TRANSFORM_BEGIN_INFO_QCOM                              = 1000282001,
	PHYSICAL_DEVICE_DEVICE_MEMORY_REPORT_FEATURES_EXT                  = 1000284000,
	DEVICE_DEVICE_MEMORY_REPORT_CREATE_INFO_EXT                        = 1000284001,
	DEVICE_MEMORY_REPORT_CALLBACK_DATA_EXT                             = 1000284002,
	PHYSICAL_DEVICE_ROBUSTNESS_2_FEATURES_EXT                          = 1000286000,
	PHYSICAL_DEVICE_ROBUSTNESS_2_PROPERTIES_EXT                        = 1000286001,
	SAMPLER_CUSTOM_BORDER_COLOR_CREATE_INFO_EXT                        = 1000287000,
	PHYSICAL_DEVICE_CUSTOM_BORDER_COLOR_PROPERTIES_EXT                 = 1000287001,
	PHYSICAL_DEVICE_CUSTOM_BORDER_COLOR_FEATURES_EXT                   = 1000287002,
	PIPELINE_LIBRARY_CREATE_INFO_KHR                                   = 1000290000,
	PRESENT_ID_KHR                                                     = 1000294000,
	PHYSICAL_DEVICE_PRESENT_ID_FEATURES_KHR                            = 1000294001,
	VIDEO_ENCODE_INFO_KHR                                              = 1000299000,
	VIDEO_ENCODE_RATE_CONTROL_INFO_KHR                                 = 1000299001,
	VIDEO_ENCODE_RATE_CONTROL_LAYER_INFO_KHR                           = 1000299002,
	VIDEO_ENCODE_CAPABILITIES_KHR                                      = 1000299003,
	PHYSICAL_DEVICE_DIAGNOSTICS_CONFIG_FEATURES_NV                     = 1000300000,
	DEVICE_DIAGNOSTICS_CONFIG_CREATE_INFO_NV                           = 1000300001,
	QUEUE_FAMILY_CHECKPOINT_PROPERTIES_2_NV                            = 1000314008,
	CHECKPOINT_DATA_2_NV                                               = 1000314009,
	PHYSICAL_DEVICE_GRAPHICS_PIPELINE_LIBRARY_FEATURES_EXT             = 1000320000,
	PHYSICAL_DEVICE_GRAPHICS_PIPELINE_LIBRARY_PROPERTIES_EXT           = 1000320001,
	GRAPHICS_PIPELINE_LIBRARY_CREATE_INFO_EXT                          = 1000320002,
	PHYSICAL_DEVICE_SHADER_SUBGROUP_UNIFORM_CONTROL_FLOW_FEATURES_KHR  = 1000323000,
	PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_ENUMS_PROPERTIES_NV          = 1000326000,
	PHYSICAL_DEVICE_FRAGMENT_SHADING_RATE_ENUMS_FEATURES_NV            = 1000326001,
	PIPELINE_FRAGMENT_SHADING_RATE_ENUM_STATE_CREATE_INFO_NV           = 1000326002,
	ACCELERATION_STRUCTURE_GEOMETRY_MOTION_TRIANGLES_DATA_NV           = 1000327000,
	PHYSICAL_DEVICE_RAY_TRACING_MOTION_BLUR_FEATURES_NV                = 1000327001,
	ACCELERATION_STRUCTURE_MOTION_INFO_NV                              = 1000327002,
	PHYSICAL_DEVICE_YCBCR_2_PLANE_444_FORMATS_FEATURES_EXT             = 1000330000,
	PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_2_FEATURES_EXT                = 1000332000,
	PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_2_PROPERTIES_EXT              = 1000332001,
	COPY_COMMAND_TRANSFORM_INFO_QCOM                                   = 1000333000,
	PHYSICAL_DEVICE_WORKGROUP_MEMORY_EXPLICIT_LAYOUT_FEATURES_KHR      = 1000336000,
	PHYSICAL_DEVICE_4444_FORMATS_FEATURES_EXT                          = 1000340000,
	PHYSICAL_DEVICE_RASTERIZATION_ORDER_ATTACHMENT_ACCESS_FEATURES_ARM = 1000342000,
	PHYSICAL_DEVICE_RGBA10X6_FORMATS_FEATURES_EXT                      = 1000344000,
	DIRECTFB_SURFACE_CREATE_INFO_EXT                                   = 1000346000,
	PHYSICAL_DEVICE_MUTABLE_DESCRIPTOR_TYPE_FEATURES_VALVE             = 1000351000,
	MUTABLE_DESCRIPTOR_TYPE_CREATE_INFO_VALVE                          = 1000351002,
	PHYSICAL_DEVICE_VERTEX_INPUT_DYNAMIC_STATE_FEATURES_EXT            = 1000352000,
	VERTEX_INPUT_BINDING_DESCRIPTION_2_EXT                             = 1000352001,
	VERTEX_INPUT_ATTRIBUTE_DESCRIPTION_2_EXT                           = 1000352002,
	PHYSICAL_DEVICE_DRM_PROPERTIES_EXT                                 = 1000353000,
	PHYSICAL_DEVICE_DEPTH_CLIP_CONTROL_FEATURES_EXT                    = 1000355000,
	PIPELINE_VIEWPORT_DEPTH_CLIP_CONTROL_CREATE_INFO_EXT               = 1000355001,
	PHYSICAL_DEVICE_PRIMITIVE_TOPOLOGY_LIST_RESTART_FEATURES_EXT       = 1000356000,
	IMPORT_MEMORY_ZIRCON_HANDLE_INFO_FUCHSIA                           = 1000364000,
	MEMORY_ZIRCON_HANDLE_PROPERTIES_FUCHSIA                            = 1000364001,
	MEMORY_GET_ZIRCON_HANDLE_INFO_FUCHSIA                              = 1000364002,
	IMPORT_SEMAPHORE_ZIRCON_HANDLE_INFO_FUCHSIA                        = 1000365000,
	SEMAPHORE_GET_ZIRCON_HANDLE_INFO_FUCHSIA                           = 1000365001,
	BUFFER_COLLECTION_CREATE_INFO_FUCHSIA                              = 1000366000,
	IMPORT_MEMORY_BUFFER_COLLECTION_FUCHSIA                            = 1000366001,
	BUFFER_COLLECTION_IMAGE_CREATE_INFO_FUCHSIA                        = 1000366002,
	BUFFER_COLLECTION_PROPERTIES_FUCHSIA                               = 1000366003,
	BUFFER_CONSTRAINTS_INFO_FUCHSIA                                    = 1000366004,
	BUFFER_COLLECTION_BUFFER_CREATE_INFO_FUCHSIA                       = 1000366005,
	IMAGE_CONSTRAINTS_INFO_FUCHSIA                                     = 1000366006,
	IMAGE_FORMAT_CONSTRAINTS_INFO_FUCHSIA                              = 1000366007,
	SYSMEM_COLOR_SPACE_FUCHSIA                                         = 1000366008,
	BUFFER_COLLECTION_CONSTRAINTS_INFO_FUCHSIA                         = 1000366009,
	SUBPASS_SHADING_PIPELINE_CREATE_INFO_HUAWEI                        = 1000369000,
	PHYSICAL_DEVICE_SUBPASS_SHADING_FEATURES_HUAWEI                    = 1000369001,
	PHYSICAL_DEVICE_SUBPASS_SHADING_PROPERTIES_HUAWEI                  = 1000369002,
	PHYSICAL_DEVICE_INVOCATION_MASK_FEATURES_HUAWEI                    = 1000370000,
	MEMORY_GET_REMOTE_ADDRESS_INFO_NV                                  = 1000371000,
	PHYSICAL_DEVICE_EXTERNAL_MEMORY_RDMA_FEATURES_NV                   = 1000371001,
	PHYSICAL_DEVICE_EXTENDED_DYNAMIC_STATE_2_FEATURES_EXT              = 1000377000,
	SCREEN_SURFACE_CREATE_INFO_QNX                                     = 1000378000,
	PHYSICAL_DEVICE_COLOR_WRITE_ENABLE_FEATURES_EXT                    = 1000381000,
	PIPELINE_COLOR_WRITE_CREATE_INFO_EXT                               = 1000381001,
	PHYSICAL_DEVICE_PRIMITIVES_GENERATED_QUERY_FEATURES_EXT            = 1000382000,
	PHYSICAL_DEVICE_IMAGE_VIEW_MIN_LOD_FEATURES_EXT                    = 1000391000,
	IMAGE_VIEW_MIN_LOD_CREATE_INFO_EXT                                 = 1000391001,
	PHYSICAL_DEVICE_MULTI_DRAW_FEATURES_EXT                            = 1000392000,
	PHYSICAL_DEVICE_MULTI_DRAW_PROPERTIES_EXT                          = 1000392001,
	PHYSICAL_DEVICE_IMAGE_2D_VIEW_OF_3D_FEATURES_EXT                   = 1000393000,
	PHYSICAL_DEVICE_BORDER_COLOR_SWIZZLE_FEATURES_EXT                  = 1000411000,
	SAMPLER_BORDER_COLOR_COMPONENT_MAPPING_CREATE_INFO_EXT             = 1000411001,
	PHYSICAL_DEVICE_PAGEABLE_DEVICE_LOCAL_MEMORY_FEATURES_EXT          = 1000412000,
	PHYSICAL_DEVICE_DESCRIPTOR_SET_HOST_MAPPING_FEATURES_VALVE         = 1000420000,
	DESCRIPTOR_SET_BINDING_REFERENCE_VALVE                             = 1000420001,
	DESCRIPTOR_SET_LAYOUT_HOST_MAPPING_INFO_VALVE                      = 1000420002,
	PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_OFFSET_FEATURES_QCOM          = 1000425000,
	PHYSICAL_DEVICE_FRAGMENT_DENSITY_MAP_OFFSET_PROPERTIES_QCOM        = 1000425001,
	SUBPASS_FRAGMENT_DENSITY_MAP_OFFSET_END_INFO_QCOM                  = 1000425002,
	PHYSICAL_DEVICE_LINEAR_COLOR_ATTACHMENT_FEATURES_NV                = 1000430000,
	PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES                          = PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES,
	PHYSICAL_DEVICE_SHADER_DRAW_PARAMETER_FEATURES                     = PHYSICAL_DEVICE_SHADER_DRAW_PARAMETERS_FEATURES,
	DEBUG_REPORT_CREATE_INFO_EXT                                       = DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT,
	RENDERING_INFO_KHR                                                 = RENDERING_INFO,
	RENDERING_ATTACHMENT_INFO_KHR                                      = RENDERING_ATTACHMENT_INFO,
	PIPELINE_RENDERING_CREATE_INFO_KHR                                 = PIPELINE_RENDERING_CREATE_INFO,
	PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES_KHR                     = PHYSICAL_DEVICE_DYNAMIC_RENDERING_FEATURES,
	COMMAND_BUFFER_INHERITANCE_RENDERING_INFO_KHR                      = COMMAND_BUFFER_INHERITANCE_RENDERING_INFO,
	ATTACHMENT_SAMPLE_COUNT_INFO_NV                                    = ATTACHMENT_SAMPLE_COUNT_INFO_AMD,
	RENDER_PASS_MULTIVIEW_CREATE_INFO_KHR                              = RENDER_PASS_MULTIVIEW_CREATE_INFO,
	PHYSICAL_DEVICE_MULTIVIEW_FEATURES_KHR                             = PHYSICAL_DEVICE_MULTIVIEW_FEATURES,
	PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES_KHR                           = PHYSICAL_DEVICE_MULTIVIEW_PROPERTIES,
	PHYSICAL_DEVICE_FEATURES_2_KHR                                     = PHYSICAL_DEVICE_FEATURES_2,
	PHYSICAL_DEVICE_PROPERTIES_2_KHR                                   = PHYSICAL_DEVICE_PROPERTIES_2,
	FORMAT_PROPERTIES_2_KHR                                            = FORMAT_PROPERTIES_2,
	IMAGE_FORMAT_PROPERTIES_2_KHR                                      = IMAGE_FORMAT_PROPERTIES_2,
	PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2_KHR                            = PHYSICAL_DEVICE_IMAGE_FORMAT_INFO_2,
	QUEUE_FAMILY_PROPERTIES_2_KHR                                      = QUEUE_FAMILY_PROPERTIES_2,
	PHYSICAL_DEVICE_MEMORY_PROPERTIES_2_KHR                            = PHYSICAL_DEVICE_MEMORY_PROPERTIES_2,
	SPARSE_IMAGE_FORMAT_PROPERTIES_2_KHR                               = SPARSE_IMAGE_FORMAT_PROPERTIES_2,
	PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2_KHR                     = PHYSICAL_DEVICE_SPARSE_IMAGE_FORMAT_INFO_2,
	MEMORY_ALLOCATE_FLAGS_INFO_KHR                                     = MEMORY_ALLOCATE_FLAGS_INFO,
	DEVICE_GROUP_RENDER_PASS_BEGIN_INFO_KHR                            = DEVICE_GROUP_RENDER_PASS_BEGIN_INFO,
	DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO_KHR                         = DEVICE_GROUP_COMMAND_BUFFER_BEGIN_INFO,
	DEVICE_GROUP_SUBMIT_INFO_KHR                                       = DEVICE_GROUP_SUBMIT_INFO,
	DEVICE_GROUP_BIND_SPARSE_INFO_KHR                                  = DEVICE_GROUP_BIND_SPARSE_INFO,
	BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO_KHR                           = BIND_BUFFER_MEMORY_DEVICE_GROUP_INFO,
	BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO_KHR                            = BIND_IMAGE_MEMORY_DEVICE_GROUP_INFO,
	PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTC_HDR_FEATURES_EXT          = PHYSICAL_DEVICE_TEXTURE_COMPRESSION_ASTC_HDR_FEATURES,
	PHYSICAL_DEVICE_GROUP_PROPERTIES_KHR                               = PHYSICAL_DEVICE_GROUP_PROPERTIES,
	DEVICE_GROUP_DEVICE_CREATE_INFO_KHR                                = DEVICE_GROUP_DEVICE_CREATE_INFO,
	PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO_KHR                     = PHYSICAL_DEVICE_EXTERNAL_IMAGE_FORMAT_INFO,
	EXTERNAL_IMAGE_FORMAT_PROPERTIES_KHR                               = EXTERNAL_IMAGE_FORMAT_PROPERTIES,
	PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO_KHR                           = PHYSICAL_DEVICE_EXTERNAL_BUFFER_INFO,
	EXTERNAL_BUFFER_PROPERTIES_KHR                                     = EXTERNAL_BUFFER_PROPERTIES,
	PHYSICAL_DEVICE_ID_PROPERTIES_KHR                                  = PHYSICAL_DEVICE_ID_PROPERTIES,
	EXTERNAL_MEMORY_BUFFER_CREATE_INFO_KHR                             = EXTERNAL_MEMORY_BUFFER_CREATE_INFO,
	EXTERNAL_MEMORY_IMAGE_CREATE_INFO_KHR                              = EXTERNAL_MEMORY_IMAGE_CREATE_INFO,
	EXPORT_MEMORY_ALLOCATE_INFO_KHR                                    = EXPORT_MEMORY_ALLOCATE_INFO,
	PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO_KHR                        = PHYSICAL_DEVICE_EXTERNAL_SEMAPHORE_INFO,
	EXTERNAL_SEMAPHORE_PROPERTIES_KHR                                  = EXTERNAL_SEMAPHORE_PROPERTIES,
	EXPORT_SEMAPHORE_CREATE_INFO_KHR                                   = EXPORT_SEMAPHORE_CREATE_INFO,
	PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES_KHR                   = PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES,
	PHYSICAL_DEVICE_FLOAT16_INT8_FEATURES_KHR                          = PHYSICAL_DEVICE_SHADER_FLOAT16_INT8_FEATURES,
	PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES_KHR                         = PHYSICAL_DEVICE_16BIT_STORAGE_FEATURES,
	DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO_KHR                         = DESCRIPTOR_UPDATE_TEMPLATE_CREATE_INFO,
	SURFACE_CAPABILITIES2_EXT                                          = SURFACE_CAPABILITIES_2_EXT,
	PHYSICAL_DEVICE_IMAGELESS_FRAMEBUFFER_FEATURES_KHR                 = PHYSICAL_DEVICE_IMAGELESS_FRAMEBUFFER_FEATURES,
	FRAMEBUFFER_ATTACHMENTS_CREATE_INFO_KHR                            = FRAMEBUFFER_ATTACHMENTS_CREATE_INFO,
	FRAMEBUFFER_ATTACHMENT_IMAGE_INFO_KHR                              = FRAMEBUFFER_ATTACHMENT_IMAGE_INFO,
	RENDER_PASS_ATTACHMENT_BEGIN_INFO_KHR                              = RENDER_PASS_ATTACHMENT_BEGIN_INFO,
	ATTACHMENT_DESCRIPTION_2_KHR                                       = ATTACHMENT_DESCRIPTION_2,
	ATTACHMENT_REFERENCE_2_KHR                                         = ATTACHMENT_REFERENCE_2,
	SUBPASS_DESCRIPTION_2_KHR                                          = SUBPASS_DESCRIPTION_2,
	SUBPASS_DEPENDENCY_2_KHR                                           = SUBPASS_DEPENDENCY_2,
	RENDER_PASS_CREATE_INFO_2_KHR                                      = RENDER_PASS_CREATE_INFO_2,
	SUBPASS_BEGIN_INFO_KHR                                             = SUBPASS_BEGIN_INFO,
	SUBPASS_END_INFO_KHR                                               = SUBPASS_END_INFO,
	PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO_KHR                            = PHYSICAL_DEVICE_EXTERNAL_FENCE_INFO,
	EXTERNAL_FENCE_PROPERTIES_KHR                                      = EXTERNAL_FENCE_PROPERTIES,
	EXPORT_FENCE_CREATE_INFO_KHR                                       = EXPORT_FENCE_CREATE_INFO,
	PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES_KHR                      = PHYSICAL_DEVICE_POINT_CLIPPING_PROPERTIES,
	RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO_KHR                = RENDER_PASS_INPUT_ATTACHMENT_ASPECT_CREATE_INFO,
	IMAGE_VIEW_USAGE_CREATE_INFO_KHR                                   = IMAGE_VIEW_USAGE_CREATE_INFO,
	PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO_KHR          = PIPELINE_TESSELLATION_DOMAIN_ORIGIN_STATE_CREATE_INFO,
	PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES_KHR                     = PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES,
	PHYSICAL_DEVICE_VARIABLE_POINTER_FEATURES_KHR                      = PHYSICAL_DEVICE_VARIABLE_POINTERS_FEATURES_KHR,
	MEMORY_DEDICATED_REQUIREMENTS_KHR                                  = MEMORY_DEDICATED_REQUIREMENTS,
	MEMORY_DEDICATED_ALLOCATE_INFO_KHR                                 = MEMORY_DEDICATED_ALLOCATE_INFO,
	PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES_EXT               = PHYSICAL_DEVICE_SAMPLER_FILTER_MINMAX_PROPERTIES,
	SAMPLER_REDUCTION_MODE_CREATE_INFO_EXT                             = SAMPLER_REDUCTION_MODE_CREATE_INFO,
	PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES_EXT                  = PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_FEATURES,
	PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES_EXT                = PHYSICAL_DEVICE_INLINE_UNIFORM_BLOCK_PROPERTIES,
	WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK_EXT                      = WRITE_DESCRIPTOR_SET_INLINE_UNIFORM_BLOCK,
	DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO_EXT               = DESCRIPTOR_POOL_INLINE_UNIFORM_BLOCK_CREATE_INFO,
	BUFFER_MEMORY_REQUIREMENTS_INFO_2_KHR                              = BUFFER_MEMORY_REQUIREMENTS_INFO_2,
	IMAGE_MEMORY_REQUIREMENTS_INFO_2_KHR                               = IMAGE_MEMORY_REQUIREMENTS_INFO_2,
	IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2_KHR                        = IMAGE_SPARSE_MEMORY_REQUIREMENTS_INFO_2,
	MEMORY_REQUIREMENTS_2_KHR                                          = MEMORY_REQUIREMENTS_2,
	SPARSE_IMAGE_MEMORY_REQUIREMENTS_2_KHR                             = SPARSE_IMAGE_MEMORY_REQUIREMENTS_2,
	IMAGE_FORMAT_LIST_CREATE_INFO_KHR                                  = IMAGE_FORMAT_LIST_CREATE_INFO,
	SAMPLER_YCBCR_CONVERSION_CREATE_INFO_KHR                           = SAMPLER_YCBCR_CONVERSION_CREATE_INFO,
	SAMPLER_YCBCR_CONVERSION_INFO_KHR                                  = SAMPLER_YCBCR_CONVERSION_INFO,
	BIND_IMAGE_PLANE_MEMORY_INFO_KHR                                   = BIND_IMAGE_PLANE_MEMORY_INFO,
	IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO_KHR                           = IMAGE_PLANE_MEMORY_REQUIREMENTS_INFO,
	PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES_KHR              = PHYSICAL_DEVICE_SAMPLER_YCBCR_CONVERSION_FEATURES,
	SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES_KHR               = SAMPLER_YCBCR_CONVERSION_IMAGE_FORMAT_PROPERTIES,
	BIND_BUFFER_MEMORY_INFO_KHR                                        = BIND_BUFFER_MEMORY_INFO,
	BIND_IMAGE_MEMORY_INFO_KHR                                         = BIND_IMAGE_MEMORY_INFO,
	DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO_EXT                = DESCRIPTOR_SET_LAYOUT_BINDING_FLAGS_CREATE_INFO,
	PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES_EXT                   = PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_FEATURES,
	PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES_EXT                 = PHYSICAL_DEVICE_DESCRIPTOR_INDEXING_PROPERTIES,
	DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO_EXT         = DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_ALLOCATE_INFO,
	DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT_EXT        = DESCRIPTOR_SET_VARIABLE_DESCRIPTOR_COUNT_LAYOUT_SUPPORT,
	PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES_KHR                       = PHYSICAL_DEVICE_MAINTENANCE_3_PROPERTIES,
	DESCRIPTOR_SET_LAYOUT_SUPPORT_KHR                                  = DESCRIPTOR_SET_LAYOUT_SUPPORT,
	DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO_EXT                       = DEVICE_QUEUE_GLOBAL_PRIORITY_CREATE_INFO_KHR,
	PHYSICAL_DEVICE_SHADER_SUBGROUP_EXTENDED_TYPES_FEATURES_KHR        = PHYSICAL_DEVICE_SHADER_SUBGROUP_EXTENDED_TYPES_FEATURES,
	PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES_KHR                          = PHYSICAL_DEVICE_8BIT_STORAGE_FEATURES,
	PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES_KHR                   = PHYSICAL_DEVICE_SHADER_ATOMIC_INT64_FEATURES,
	PIPELINE_CREATION_FEEDBACK_CREATE_INFO_EXT                         = PIPELINE_CREATION_FEEDBACK_CREATE_INFO,
	PHYSICAL_DEVICE_DRIVER_PROPERTIES_KHR                              = PHYSICAL_DEVICE_DRIVER_PROPERTIES,
	PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES_KHR                      = PHYSICAL_DEVICE_FLOAT_CONTROLS_PROPERTIES,
	PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES_KHR               = PHYSICAL_DEVICE_DEPTH_STENCIL_RESOLVE_PROPERTIES,
	SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE_KHR                      = SUBPASS_DESCRIPTION_DEPTH_STENCIL_RESOLVE,
	PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES_KHR                    = PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_FEATURES,
	PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_PROPERTIES_KHR                  = PHYSICAL_DEVICE_TIMELINE_SEMAPHORE_PROPERTIES,
	SEMAPHORE_TYPE_CREATE_INFO_KHR                                     = SEMAPHORE_TYPE_CREATE_INFO,
	TIMELINE_SEMAPHORE_SUBMIT_INFO_KHR                                 = TIMELINE_SEMAPHORE_SUBMIT_INFO,
	SEMAPHORE_WAIT_INFO_KHR                                            = SEMAPHORE_WAIT_INFO,
	SEMAPHORE_SIGNAL_INFO_KHR                                          = SEMAPHORE_SIGNAL_INFO,
	QUERY_POOL_CREATE_INFO_INTEL                                       = QUERY_POOL_PERFORMANCE_QUERY_CREATE_INFO_INTEL,
	PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES_KHR                   = PHYSICAL_DEVICE_VULKAN_MEMORY_MODEL_FEATURES,
	PHYSICAL_DEVICE_SHADER_TERMINATE_INVOCATION_FEATURES_KHR           = PHYSICAL_DEVICE_SHADER_TERMINATE_INVOCATION_FEATURES,
	PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES_EXT                   = PHYSICAL_DEVICE_SCALAR_BLOCK_LAYOUT_FEATURES,
	PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_PROPERTIES_EXT               = PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_PROPERTIES,
	PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO_EXT       = PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO,
	PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_FEATURES_EXT                 = PHYSICAL_DEVICE_SUBGROUP_SIZE_CONTROL_FEATURES,
	PHYSICAL_DEVICE_SEPARATE_DEPTH_STENCIL_LAYOUTS_FEATURES_KHR        = PHYSICAL_DEVICE_SEPARATE_DEPTH_STENCIL_LAYOUTS_FEATURES,
	ATTACHMENT_REFERENCE_STENCIL_LAYOUT_KHR                            = ATTACHMENT_REFERENCE_STENCIL_LAYOUT,
	ATTACHMENT_DESCRIPTION_STENCIL_LAYOUT_KHR                          = ATTACHMENT_DESCRIPTION_STENCIL_LAYOUT,
	PHYSICAL_DEVICE_BUFFER_ADDRESS_FEATURES_EXT                        = PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_EXT,
	BUFFER_DEVICE_ADDRESS_INFO_EXT                                     = BUFFER_DEVICE_ADDRESS_INFO,
	PHYSICAL_DEVICE_TOOL_PROPERTIES_EXT                                = PHYSICAL_DEVICE_TOOL_PROPERTIES,
	IMAGE_STENCIL_USAGE_CREATE_INFO_EXT                                = IMAGE_STENCIL_USAGE_CREATE_INFO,
	PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES_KHR        = PHYSICAL_DEVICE_UNIFORM_BUFFER_STANDARD_LAYOUT_FEATURES,
	PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES_KHR                 = PHYSICAL_DEVICE_BUFFER_DEVICE_ADDRESS_FEATURES,
	BUFFER_DEVICE_ADDRESS_INFO_KHR                                     = BUFFER_DEVICE_ADDRESS_INFO,
	BUFFER_OPAQUE_CAPTURE_ADDRESS_CREATE_INFO_KHR                      = BUFFER_OPAQUE_CAPTURE_ADDRESS_CREATE_INFO,
	MEMORY_OPAQUE_CAPTURE_ADDRESS_ALLOCATE_INFO_KHR                    = MEMORY_OPAQUE_CAPTURE_ADDRESS_ALLOCATE_INFO,
	DEVICE_MEMORY_OPAQUE_CAPTURE_ADDRESS_INFO_KHR                      = DEVICE_MEMORY_OPAQUE_CAPTURE_ADDRESS_INFO,
	PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES_EXT                      = PHYSICAL_DEVICE_HOST_QUERY_RESET_FEATURES,
	PHYSICAL_DEVICE_SHADER_DEMOTE_TO_HELPER_INVOCATION_FEATURES_EXT    = PHYSICAL_DEVICE_SHADER_DEMOTE_TO_HELPER_INVOCATION_FEATURES,
	PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_FEATURES_KHR            = PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_FEATURES,
	PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_PROPERTIES_KHR          = PHYSICAL_DEVICE_SHADER_INTEGER_DOT_PRODUCT_PROPERTIES,
	PHYSICAL_DEVICE_TEXEL_BUFFER_ALIGNMENT_PROPERTIES_EXT              = PHYSICAL_DEVICE_TEXEL_BUFFER_ALIGNMENT_PROPERTIES,
	PHYSICAL_DEVICE_PRIVATE_DATA_FEATURES_EXT                          = PHYSICAL_DEVICE_PRIVATE_DATA_FEATURES,
	DEVICE_PRIVATE_DATA_CREATE_INFO_EXT                                = DEVICE_PRIVATE_DATA_CREATE_INFO,
	PRIVATE_DATA_SLOT_CREATE_INFO_EXT                                  = PRIVATE_DATA_SLOT_CREATE_INFO,
	PHYSICAL_DEVICE_PIPELINE_CREATION_CACHE_CONTROL_FEATURES_EXT       = PHYSICAL_DEVICE_PIPELINE_CREATION_CACHE_CONTROL_FEATURES,
	MEMORY_BARRIER_2_KHR                                               = MEMORY_BARRIER_2,
	BUFFER_MEMORY_BARRIER_2_KHR                                        = BUFFER_MEMORY_BARRIER_2,
	IMAGE_MEMORY_BARRIER_2_KHR                                         = IMAGE_MEMORY_BARRIER_2,
	DEPENDENCY_INFO_KHR                                                = DEPENDENCY_INFO,
	SUBMIT_INFO_2_KHR                                                  = SUBMIT_INFO_2,
	SEMAPHORE_SUBMIT_INFO_KHR                                          = SEMAPHORE_SUBMIT_INFO,
	COMMAND_BUFFER_SUBMIT_INFO_KHR                                     = COMMAND_BUFFER_SUBMIT_INFO,
	PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES_KHR                     = PHYSICAL_DEVICE_SYNCHRONIZATION_2_FEATURES,
	PHYSICAL_DEVICE_ZERO_INITIALIZE_WORKGROUP_MEMORY_FEATURES_KHR      = PHYSICAL_DEVICE_ZERO_INITIALIZE_WORKGROUP_MEMORY_FEATURES,
	PHYSICAL_DEVICE_IMAGE_ROBUSTNESS_FEATURES_EXT                      = PHYSICAL_DEVICE_IMAGE_ROBUSTNESS_FEATURES,
	COPY_BUFFER_INFO_2_KHR                                             = COPY_BUFFER_INFO_2,
	COPY_IMAGE_INFO_2_KHR                                              = COPY_IMAGE_INFO_2,
	COPY_BUFFER_TO_IMAGE_INFO_2_KHR                                    = COPY_BUFFER_TO_IMAGE_INFO_2,
	COPY_IMAGE_TO_BUFFER_INFO_2_KHR                                    = COPY_IMAGE_TO_BUFFER_INFO_2,
	BLIT_IMAGE_INFO_2_KHR                                              = BLIT_IMAGE_INFO_2,
	RESOLVE_IMAGE_INFO_2_KHR                                           = RESOLVE_IMAGE_INFO_2,
	BUFFER_COPY_2_KHR                                                  = BUFFER_COPY_2,
	IMAGE_COPY_2_KHR                                                   = IMAGE_COPY_2,
	IMAGE_BLIT_2_KHR                                                   = IMAGE_BLIT_2,
	BUFFER_IMAGE_COPY_2_KHR                                            = BUFFER_IMAGE_COPY_2,
	IMAGE_RESOLVE_2_KHR                                                = IMAGE_RESOLVE_2,
	FORMAT_PROPERTIES_3_KHR                                            = FORMAT_PROPERTIES_3,
	PHYSICAL_DEVICE_GLOBAL_PRIORITY_QUERY_FEATURES_EXT                 = PHYSICAL_DEVICE_GLOBAL_PRIORITY_QUERY_FEATURES_KHR,
	QUEUE_FAMILY_GLOBAL_PRIORITY_PROPERTIES_EXT                        = QUEUE_FAMILY_GLOBAL_PRIORITY_PROPERTIES_KHR,
	PHYSICAL_DEVICE_MAINTENANCE_4_FEATURES_KHR                         = PHYSICAL_DEVICE_MAINTENANCE_4_FEATURES,
	PHYSICAL_DEVICE_MAINTENANCE_4_PROPERTIES_KHR                       = PHYSICAL_DEVICE_MAINTENANCE_4_PROPERTIES,
	DEVICE_BUFFER_MEMORY_REQUIREMENTS_KHR                              = DEVICE_BUFFER_MEMORY_REQUIREMENTS,
	DEVICE_IMAGE_MEMORY_REQUIREMENTS_KHR                               = DEVICE_IMAGE_MEMORY_REQUIREMENTS,
}

SubgroupFeatureFlags :: distinct bit_set[SubgroupFeatureFlag; Flags]
SubgroupFeatureFlag :: enum Flags {
	BASIC            = 0,
	VOTE             = 1,
	ARITHMETIC       = 2,
	BALLOT           = 3,
	SHUFFLE          = 4,
	SHUFFLE_RELATIVE = 5,
	CLUSTERED        = 6,
	QUAD             = 7,
	PARTITIONED_NV   = 8,
}

SubmitFlags :: distinct bit_set[SubmitFlag; Flags]
SubmitFlag :: enum Flags {
	PROTECTED     = 0,
	PROTECTED_KHR = PROTECTED,
}

SubpassContents :: enum c.int {
	INLINE                    = 0,
	SECONDARY_COMMAND_BUFFERS = 1,
}

SubpassDescriptionFlags :: distinct bit_set[SubpassDescriptionFlag; Flags]
SubpassDescriptionFlag :: enum Flags {
	PER_VIEW_ATTRIBUTES_NVX                           = 0,
	PER_VIEW_POSITION_X_ONLY_NVX                      = 1,
	FRAGMENT_REGION_QCOM                              = 2,
	SHADER_RESOLVE_QCOM                               = 3,
	RASTERIZATION_ORDER_ATTACHMENT_COLOR_ACCESS_ARM   = 4,
	RASTERIZATION_ORDER_ATTACHMENT_DEPTH_ACCESS_ARM   = 5,
	RASTERIZATION_ORDER_ATTACHMENT_STENCIL_ACCESS_ARM = 6,
}

SurfaceCounterFlagsEXT :: distinct bit_set[SurfaceCounterFlagEXT; Flags]
SurfaceCounterFlagEXT :: enum Flags {
	VBLANK = 0,
}

SurfaceTransformFlagsKHR :: distinct bit_set[SurfaceTransformFlagKHR; Flags]
SurfaceTransformFlagKHR :: enum Flags {
	IDENTITY                     = 0,
	ROTATE_90                    = 1,
	ROTATE_180                   = 2,
	ROTATE_270                   = 3,
	HORIZONTAL_MIRROR            = 4,
	HORIZONTAL_MIRROR_ROTATE_90  = 5,
	HORIZONTAL_MIRROR_ROTATE_180 = 6,
	HORIZONTAL_MIRROR_ROTATE_270 = 7,
	INHERIT                      = 8,
}

SwapchainCreateFlagsKHR :: distinct bit_set[SwapchainCreateFlagKHR; Flags]
SwapchainCreateFlagKHR :: enum Flags {
	SPLIT_INSTANCE_BIND_REGIONS = 0,
	PROTECTED                   = 1,
	MUTABLE_FORMAT              = 2,
}

SystemAllocationScope :: enum c.int {
	COMMAND  = 0,
	OBJECT   = 1,
	CACHE    = 2,
	DEVICE   = 3,
	INSTANCE = 4,
}

TessellationDomainOrigin :: enum c.int {
	UPPER_LEFT     = 0,
	LOWER_LEFT     = 1,
	UPPER_LEFT_KHR = UPPER_LEFT,
	LOWER_LEFT_KHR = LOWER_LEFT,
}

TimeDomainEXT :: enum c.int {
	DEVICE                    = 0,
	CLOCK_MONOTONIC           = 1,
	CLOCK_MONOTONIC_RAW       = 2,
	QUERY_PERFORMANCE_COUNTER = 3,
}

ToolPurposeFlags :: distinct bit_set[ToolPurposeFlag; Flags]
ToolPurposeFlag :: enum Flags {
	VALIDATION              = 0,
	PROFILING               = 1,
	TRACING                 = 2,
	ADDITIONAL_FEATURES     = 3,
	MODIFYING_FEATURES      = 4,
	DEBUG_REPORTING_EXT     = 5,
	DEBUG_MARKERS_EXT       = 6,
	VALIDATION_EXT          = VALIDATION,
	PROFILING_EXT           = PROFILING,
	TRACING_EXT             = TRACING,
	ADDITIONAL_FEATURES_EXT = ADDITIONAL_FEATURES,
	MODIFYING_FEATURES_EXT  = MODIFYING_FEATURES,
}

ValidationCacheHeaderVersionEXT :: enum c.int {
	ONE = 1,
}

ValidationCheckEXT :: enum c.int {
	ALL     = 0,
	SHADERS = 1,
}

ValidationFeatureDisableEXT :: enum c.int {
	ALL                     = 0,
	SHADERS                 = 1,
	THREAD_SAFETY           = 2,
	API_PARAMETERS          = 3,
	OBJECT_LIFETIMES        = 4,
	CORE_CHECKS             = 5,
	UNIQUE_HANDLES          = 6,
	SHADER_VALIDATION_CACHE = 7,
}

ValidationFeatureEnableEXT :: enum c.int {
	GPU_ASSISTED                      = 0,
	GPU_ASSISTED_RESERVE_BINDING_SLOT = 1,
	BEST_PRACTICES                    = 2,
	DEBUG_PRINTF                      = 3,
	SYNCHRONIZATION_VALIDATION        = 4,
}

VendorId :: enum c.int {
	VIV      = 0x10001,
	VSI      = 0x10002,
	KAZAN    = 0x10003,
	CODEPLAY = 0x10004,
	MESA     = 0x10005,
	POCL     = 0x10006,
}

VertexInputRate :: enum c.int {
	VERTEX   = 0,
	INSTANCE = 1,
}

ViewportCoordinateSwizzleNV :: enum c.int {
	POSITIVE_X = 0,
	NEGATIVE_X = 1,
	POSITIVE_Y = 2,
	NEGATIVE_Y = 3,
	POSITIVE_Z = 4,
	NEGATIVE_Z = 5,
	POSITIVE_W = 6,
	NEGATIVE_W = 7,
}

AccelerationStructureMotionInfoFlagsNV               :: distinct bit_set[AccelerationStructureMotionInfoFlagNV; Flags]
AccelerationStructureMotionInfoFlagNV                :: enum u32 {}
AccelerationStructureMotionInstanceFlagsNV           :: distinct bit_set[AccelerationStructureMotionInstanceFlagNV; Flags]
AccelerationStructureMotionInstanceFlagNV            :: enum u32 {}
BufferViewCreateFlags                                :: distinct bit_set[BufferViewCreateFlag; Flags]
BufferViewCreateFlag                                 :: enum u32 {}
CommandPoolTrimFlags                                 :: distinct bit_set[CommandPoolTrimFlag; Flags]
CommandPoolTrimFlag                                  :: enum u32 {}
DebugUtilsMessengerCallbackDataFlagsEXT              :: distinct bit_set[DebugUtilsMessengerCallbackDataFlagEXT; Flags]
DebugUtilsMessengerCallbackDataFlagEXT               :: enum u32 {}
DebugUtilsMessengerCreateFlagsEXT                    :: distinct bit_set[DebugUtilsMessengerCreateFlagEXT; Flags]
DebugUtilsMessengerCreateFlagEXT                     :: enum u32 {}
DescriptorPoolResetFlags                             :: distinct bit_set[DescriptorPoolResetFlag; Flags]
DescriptorPoolResetFlag                              :: enum u32 {}
DescriptorUpdateTemplateCreateFlags                  :: distinct bit_set[DescriptorUpdateTemplateCreateFlag; Flags]
DescriptorUpdateTemplateCreateFlag                   :: enum u32 {}
DeviceCreateFlags                                    :: distinct bit_set[DeviceCreateFlag; Flags]
DeviceCreateFlag                                     :: enum u32 {}
DeviceMemoryReportFlagsEXT                           :: distinct bit_set[DeviceMemoryReportFlagEXT; Flags]
DeviceMemoryReportFlagEXT                            :: enum u32 {}
DisplayModeCreateFlagsKHR                            :: distinct bit_set[DisplayModeCreateFlagKHR; Flags]
DisplayModeCreateFlagKHR                             :: enum u32 {}
DisplaySurfaceCreateFlagsKHR                         :: distinct bit_set[DisplaySurfaceCreateFlagKHR; Flags]
DisplaySurfaceCreateFlagKHR                          :: enum u32 {}
HeadlessSurfaceCreateFlagsEXT                        :: distinct bit_set[HeadlessSurfaceCreateFlagEXT; Flags]
HeadlessSurfaceCreateFlagEXT                         :: enum u32 {}
IOSSurfaceCreateFlagsMVK                             :: distinct bit_set[IOSSurfaceCreateFlagMVK; Flags]
IOSSurfaceCreateFlagMVK                              :: enum u32 {}
MacOSSurfaceCreateFlagsMVK                           :: distinct bit_set[MacOSSurfaceCreateFlagMVK; Flags]
MacOSSurfaceCreateFlagMVK                            :: enum u32 {}
MemoryMapFlags                                       :: distinct bit_set[MemoryMapFlag; Flags]
MemoryMapFlag                                        :: enum u32 {}
MetalSurfaceCreateFlagsEXT                           :: distinct bit_set[MetalSurfaceCreateFlagEXT; Flags]
MetalSurfaceCreateFlagEXT                            :: enum u32 {}
PipelineCoverageModulationStateCreateFlagsNV         :: distinct bit_set[PipelineCoverageModulationStateCreateFlagNV; Flags]
PipelineCoverageModulationStateCreateFlagNV          :: enum u32 {}
PipelineCoverageReductionStateCreateFlagsNV          :: distinct bit_set[PipelineCoverageReductionStateCreateFlagNV; Flags]
PipelineCoverageReductionStateCreateFlagNV           :: enum u32 {}
PipelineCoverageToColorStateCreateFlagsNV            :: distinct bit_set[PipelineCoverageToColorStateCreateFlagNV; Flags]
PipelineCoverageToColorStateCreateFlagNV             :: enum u32 {}
PipelineDiscardRectangleStateCreateFlagsEXT          :: distinct bit_set[PipelineDiscardRectangleStateCreateFlagEXT; Flags]
PipelineDiscardRectangleStateCreateFlagEXT           :: enum u32 {}
PipelineDynamicStateCreateFlags                      :: distinct bit_set[PipelineDynamicStateCreateFlag; Flags]
PipelineDynamicStateCreateFlag                       :: enum u32 {}
PipelineInputAssemblyStateCreateFlags                :: distinct bit_set[PipelineInputAssemblyStateCreateFlag; Flags]
PipelineInputAssemblyStateCreateFlag                 :: enum u32 {}
PipelineMultisampleStateCreateFlags                  :: distinct bit_set[PipelineMultisampleStateCreateFlag; Flags]
PipelineMultisampleStateCreateFlag                   :: enum u32 {}
PipelineRasterizationConservativeStateCreateFlagsEXT :: distinct bit_set[PipelineRasterizationConservativeStateCreateFlagEXT; Flags]
PipelineRasterizationConservativeStateCreateFlagEXT  :: enum u32 {}
PipelineRasterizationDepthClipStateCreateFlagsEXT    :: distinct bit_set[PipelineRasterizationDepthClipStateCreateFlagEXT; Flags]
PipelineRasterizationDepthClipStateCreateFlagEXT     :: enum u32 {}
PipelineRasterizationStateCreateFlags                :: distinct bit_set[PipelineRasterizationStateCreateFlag; Flags]
PipelineRasterizationStateCreateFlag                 :: enum u32 {}
PipelineRasterizationStateStreamCreateFlagsEXT       :: distinct bit_set[PipelineRasterizationStateStreamCreateFlagEXT; Flags]
PipelineRasterizationStateStreamCreateFlagEXT        :: enum u32 {}
PipelineTessellationStateCreateFlags                 :: distinct bit_set[PipelineTessellationStateCreateFlag; Flags]
PipelineTessellationStateCreateFlag                  :: enum u32 {}
PipelineVertexInputStateCreateFlags                  :: distinct bit_set[PipelineVertexInputStateCreateFlag; Flags]
PipelineVertexInputStateCreateFlag                   :: enum u32 {}
PipelineViewportStateCreateFlags                     :: distinct bit_set[PipelineViewportStateCreateFlag; Flags]
PipelineViewportStateCreateFlag                      :: enum u32 {}
PipelineViewportSwizzleStateCreateFlagsNV            :: distinct bit_set[PipelineViewportSwizzleStateCreateFlagNV; Flags]
PipelineViewportSwizzleStateCreateFlagNV             :: enum u32 {}
PrivateDataSlotCreateFlags                           :: distinct bit_set[PrivateDataSlotCreateFlag; Flags]
PrivateDataSlotCreateFlag                            :: enum u32 {}
QueryPoolCreateFlags                                 :: distinct bit_set[QueryPoolCreateFlag; Flags]
QueryPoolCreateFlag                                  :: enum u32 {}
SemaphoreCreateFlags                                 :: distinct bit_set[SemaphoreCreateFlag; Flags]
SemaphoreCreateFlag                                  :: enum u32 {}
ShaderModuleCreateFlags                              :: distinct bit_set[ShaderModuleCreateFlag; Flags]
ShaderModuleCreateFlag                               :: enum u32 {}
ValidationCacheCreateFlagsEXT                        :: distinct bit_set[ValidationCacheCreateFlagEXT; Flags]
ValidationCacheCreateFlagEXT                         :: enum u32 {}
Win32SurfaceCreateFlagsKHR                           :: distinct bit_set[Win32SurfaceCreateFlagKHR; Flags]
Win32SurfaceCreateFlagKHR                            :: enum u32 {}


