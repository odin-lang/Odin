package wgpu

import "base:intrinsics"
import "core:fmt"
import "core:strings"

WGPU_SHARED :: #config(WGPU_SHARED, false)
WGPU_DEBUG  :: #config(WGPU_DEBUG,  false)

@(private) TYPE :: "debug" when WGPU_DEBUG else "release"

when ODIN_OS == .Windows {
	@(private) ARCH :: "x86_64"   when ODIN_ARCH == .amd64 else "x86_64" when ODIN_ARCH == .i386 else #panic("unsupported WGPU Native architecture")
	@(private) EXT  :: ".dll.lib" when WGPU_SHARED else ".lib"
	@(private) LIB  :: "lib/wgpu-windows-" + ARCH + "-" + TYPE + "/wgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.1, make sure to read the README at '" + #directory + "README.md'")
	}

	foreign import libwgpu {
		LIB,
		"system:d3dcompiler.lib",
		"system:ws2_32.lib",
		"system:userenv.lib",
		"system:bcrypt.lib",
		"system:ntdll.lib",
		"system:opengl32.lib",
		"system:advapi32.lib",
		"system:user32.lib",
		"system:gdi32.lib",
		"system:ole32.lib",
		"system:oleaut32.lib",
		"system:propsys.lib",
		"system:runtimeobject.lib",
	}
} else when ODIN_OS == .Darwin {
	@(private) ARCH :: "x86_64" when ODIN_ARCH == .amd64 else "aarch64" when ODIN_ARCH == .arm64 else #panic("unsupported WGPU Native architecture")
	@(private) EXT  :: ".dylib" when WGPU_SHARED else ".a"
	@(private) LIB  :: "lib/wgpu-macos-" + ARCH + "-" + TYPE + "/libwgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.1, make sure to read the README at '" + #directory + "README.md'")
	}

	foreign import libwgpu {
		LIB,
		"system:CoreFoundation.framework",
		"system:QuartzCore.framework",
		"system:Metal.framework",
	}
} else when ODIN_OS == .Linux {
	@(private) ARCH :: "x86_64" when ODIN_ARCH == .amd64 else "aarch64" when ODIN_ARCH == .arm64 else #panic("unsupported WGPU Native architecture")
	@(private) EXT  :: ".so"    when WGPU_SHARED else ".a"
	@(private) LIB  :: "lib/wgpu-linux-" + ARCH + "-" + TYPE + "/libwgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.1, make sure to read the README at '" + #directory + "README.md'")
	}

	foreign import libwgpu {
		LIB,
		"system:dl",
		"system:m",
	}
} else when ODIN_OS == .JS {
	foreign import libwgpu "wgpu"
}

ARRAY_LAYER_COUNT_UNDEFINED :: max(u32)
COPY_STRIDE_UNDEFINED :: max(u32)
DEPTH_SLICE_UNDEFINED :: max(u32)
LIMIT_U32_UNDEFINED :: max(u32)
LIMIT_U64_UNDEFINED :: max(u64)
MIP_LEVEL_COUNT_UNDEFINED :: max(u32)
QUERY_SET_INDEX_UNDEFINED :: max(u32)
WHOLE_MAP_SIZE :: max(uint)
WHOLE_SIZE :: max(u64)

Flags :: u64

/**
 * Nullable value defining a pointer+length view into a UTF-8 encoded string.
 *
 * Values passed into the API may use the special length value @ref STRLEN
 * to indicate a null-terminated string.
 * Non-null values passed out of the API (for example as callback arguments)
 * always provide an explicit length and **may or may not be null-terminated**.
 *
 * Some inputs to the API accept null values. Those which do not accept null
 * values "default" to the empty string when null values are passed.
 *
 * Values are encoded as follows:
 * - `{nil, STRLEN}`: the null value.
 * - `{non_nil_pointer, STRLEN}`: a null-terminated string view.
 * - `{any, 0}`: the empty string.
 * - `{nil, non_zero_length}`: not allowed (null dereference).
 * - `{non_nil_pointer, non_zero_length}`: an explictly-sized string view with
 *   size `non_zero_length` (in bytes).
 *
 * For info on how this is used in various places, see \ref Strings.
 */
StringView :: struct {
	data: cstring,
	length: uint,
}

STRLEN :: max(uint)

StringView_Formatter :: proc(fi: ^fmt.Info, arg: any, verb: rune) -> bool {
	v := cast(^StringView)arg.data
	switch verb {
	case 'v', 's', 'q':
		switch {
		case v^ == StringView_CreateNil():
			fmt.fmt_string(fi, "nil", verb)

		case v.length == 0:
			fmt.fmt_string(fi, "", verb)

		case v.length == STRLEN:
			fmt.fmt_cstring(fi, v.data, verb)

		case:
			s := strings.string_from_ptr(transmute([^]u8)(v.data), int(v.length))
			fmt.fmt_string(fi, s, verb)
		}
		return true

	case:
		return false
	}
}

StringView_CreateNil :: proc() -> StringView {
	return {nil, STRLEN}
}

StringView_CreateEmpty :: proc() -> StringView {
	return {nil, 0}
}

StringView_CreateCString :: proc(str: cstring) -> StringView {
	return {str, STRLEN}
}

StringView_CreateString :: proc(str: string) -> StringView {
	return {strings.unsafe_string_to_cstring(str), len(str)}
}

StringView_Create :: proc {
	StringView_CreateCString,
	StringView_CreateString,
}

Adapter :: distinct rawptr
BindGroup :: distinct rawptr
BindGroupLayout :: distinct rawptr
Buffer :: distinct rawptr
CommandBuffer :: distinct rawptr
CommandEncoder :: distinct rawptr
ComputePassEncoder :: distinct rawptr
ComputePipeline :: distinct rawptr
Device :: distinct rawptr
Instance :: distinct rawptr
PipelineLayout :: distinct rawptr
QuerySet :: distinct rawptr
Queue :: distinct rawptr
RenderBundle :: distinct rawptr
RenderBundleEncoder :: distinct rawptr
RenderPassEncoder :: distinct rawptr
RenderPipeline :: distinct rawptr
Sampler :: distinct rawptr
ShaderModule :: distinct rawptr
Surface :: distinct rawptr
Texture :: distinct rawptr
TextureView :: distinct rawptr

AdapterType :: enum i32 {
	DiscreteGPU = 0x00000001,
	IntegratedGPU = 0x00000002,
	CPU = 0x00000003,
	Unknown = 0x00000004,
}

AddressMode :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	ClampToEdge = 0x00000001,
	Repeat = 0x00000002,
	MirrorRepeat = 0x00000003,
}

BackendType :: enum i32 {
	Undefined = 0x00000000,
	Null = 0x00000001,
	WebGPU = 0x00000002,
	D3D11 = 0x00000003,
	D3D12 = 0x00000004,
	Metal = 0x00000005,
	Vulkan = 0x00000006,
	OpenGL = 0x00000007,
	OpenGLES = 0x00000008,
}

BlendFactor :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Zero = 0x00000001,
	One = 0x00000002,
	Src = 0x00000003,
	OneMinusSrc = 0x00000004,
	SrcAlpha = 0x00000005,
	OneMinusSrcAlpha = 0x00000006,
	Dst = 0x00000007,
	OneMinusDst = 0x00000008,
	DstAlpha = 0x00000009,
	OneMinusDstAlpha = 0x0000000A,
	SrcAlphaSaturated = 0x0000000B,
	Constant = 0x0000000C,
	OneMinusConstant = 0x0000000D,
	Src1 = 0x0000000E,
	OneMinusSrc1 = 0x0000000F,
	Src1Alpha = 0x00000010,
	OneMinusSrc1Alpha = 0x00000011,
}

BlendOperation :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Add = 0x00000001,
	Subtract = 0x00000002,
	ReverseSubtract = 0x00000003,
	Min = 0x00000004,
	Max = 0x00000005,
}

BufferBindingType :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates that this @ref BufferBindingLayout member of
	 * its parent @ref WGPUBindGroupLayoutEntry is not used.
	 * (See also @ref SentinelValues.)
	 */
	BindingNotUsed = 0x00000000,
	/**
	 * `0x00000001`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000001,
	Uniform = 0x00000002,
	Storage = 0x00000003,
	ReadOnlyStorage = 0x00000004,
}

BufferMapState :: enum i32 {
	Unmapped = 0x00000001,
	Pending = 0x00000002,
	Mapped = 0x00000003,
}

/**
 * The callback mode controls how a callback for an asynchronous operation may be fired. See @ref Asynchronous-Operations for how these are used.
 */
CallbackMode :: enum i32 {
	/**
	 * `0x00000001`.
	 * Callbacks created with `WaitAnyOnly`:
	 * - fire when the asynchronous operation's future is passed to a call to `InstanceWaitAny`
	 *   AND the operation has already completed or it completes inside the call to `InstanceWaitAny`.
	 */
	WaitAnyOnly = 0x00000001,
	/**
	 * `0x00000002`.
	 * Callbacks created with `AllowProcessEvents`:
	 * - fire for the same reasons as callbacks created with `WaitAnyOnly`
	 * - fire inside a call to `InstanceProcessEvents` if the asynchronous operation is complete.
	 */
	AllowProcessEvents = 0x00000002,
	/**
	 * `0x00000003`.
	 * Callbacks created with `AllowSpontaneous`:
	 * - fire for the same reasons as callbacks created with `AllowProcessEvents`
	 * - **may** fire spontaneously on an arbitrary or application thread, when the WebGPU implementations discovers that the asynchronous operation is complete.
	 *
	 *   Implementations _should_ fire spontaneous callbacks as soon as possible.
	 *
	 * @note Because spontaneous callbacks may fire at an arbitrary time on an arbitrary thread, applications should take extra care when acquiring locks or mutating state inside the callback. It undefined behavior to re-entrantly call into the webgpu.h API if the callback fires while inside the callstack of another webgpu.h function that is not `InstanceWaitAny` or `InstanceProcessEvents`.
	 */
	AllowSpontaneous = 0x00000003,
}

CompareFunction :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Never = 0x00000001,
	Less = 0x00000002,
	Equal = 0x00000003,
	LessEqual = 0x00000004,
	Greater = 0x00000005,
	NotEqual = 0x00000006,
	GreaterEqual = 0x00000007,
	Always = 0x00000008,
}

CompilationInfoRequestStatus :: enum i32 {
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	Error = 0x00000003,
	Unknown = 0x00000004,
}

CompilationMessageType :: enum i32 {
	Error = 0x00000001,
	Warning = 0x00000002,
	Info = 0x00000003,
}

/**
 * Describes how frames are composited with other contents on the screen when `SurfacePresent` is called.
 */
CompositeAlphaMode :: enum i32 {
	/**
	 * `0x00000000`.
	 * Lets the WebGPU implementation choose the best mode (supported, and with the best performance) between @ref Opaque or @ref Inherit.
	 */
	Auto = 0x00000000,
	/**
	 * `0x00000001`.
	 * The alpha component of the image is ignored and teated as if it is always 1.0.
	 */
	Opaque = 0x00000001,
	/**
	 * `0x00000002`.
	 * The alpha component is respected and non-alpha components are assumed to be already multiplied with the alpha component. For example, (0.5, 0, 0, 0.5) is semi-transparent bright red.
	 */
	Premultiplied = 0x00000002,
	/**
	 * `0x00000003`.
	 * The alpha component is respected and non-alpha components are assumed to NOT be already multiplied with the alpha component. For example, (1.0, 0, 0, 0.5) is semi-transparent bright red.
	 */
	Unpremultiplied = 0x00000003,
	/**
	 * `0x00000004`.
	 * The handling of the alpha component is unknown to WebGPU and should be handled by the application using system-specific APIs. This mode may be unavailable (for example on Wasm).
	 */
	Inherit = 0x00000004,
}

CreatePipelineAsyncStatus :: enum i32 {
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	ValidationError = 0x00000003,
	InternalError = 0x00000004,
	Unknown = 0x00000005,
}

CullMode :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	None = 0x00000001,
	Front = 0x00000002,
	Back = 0x00000003,
}

DeviceLostReason :: enum i32 {
	Unknown = 0x00000001,
	Destroyed = 0x00000002,
	InstanceDropped = 0x00000003,
	FailedCreation = 0x00000004,
}

ErrorFilter :: enum i32 {
	Validation = 0x00000001,
	OutOfMemory = 0x00000002,
	Internal = 0x00000003,
}

ErrorType :: enum i32 {
	NoError = 0x00000001,
	Validation = 0x00000002,
	OutOfMemory = 0x00000003,
	Internal = 0x00000004,
	Unknown = 0x00000005,
}

FeatureLevel :: enum i32 {
	/**
	 * `0x00000001`.
	 * "Compatibility" profile which can be supported on OpenGL ES 3.1.
	 */
	Compatibility = 0x00000001,
	/**
	 * `0x00000002`.
	 * "Core" profile which can be supported on Vulkan/Metal/D3D12.
	 */
	Core = 0x00000002,
}

FeatureName :: enum i32 {
	// WebGPU.
	Undefined = 0x00000000,
	DepthClipControl = 0x00000001,
	Depth32FloatStencil8 = 0x00000002,
	TimestampQuery = 0x00000003,
	TextureCompressionBC = 0x00000004,
	TextureCompressionBCSliced3D = 0x00000005,
	TextureCompressionETC2 = 0x00000006,
	TextureCompressionASTC = 0x00000007,
	TextureCompressionASTCSliced3D = 0x00000008,
	IndirectFirstInstance = 0x00000009,
	ShaderF16 = 0x0000000A,
	RG11B10UfloatRenderable = 0x0000000B,
	BGRA8UnormStorage = 0x0000000C,
	Float32Filterable = 0x0000000D,
	Float32Blendable = 0x0000000E,
	ClipDistances = 0x0000000F,
	DualSourceBlending = 0x00000010,

	// Native.
	PushConstants = 0x00030001,
	TextureAdapterSpecificFormatFeatures = 0x00030002,
	MultiDrawIndirect = 0x00030003,
	MultiDrawIndirectCount = 0x00030004,
	VertexWritableStorage = 0x00030005,
	TextureBindingArray = 0x00030006,
	SampledTextureAndStorageBufferArrayNonUniformIndexing = 0x00030007,
	PipelineStatisticsQuery = 0x00030008,
	StorageResourceBindingArray = 0x00030009,
	PartiallyBoundBindingArray = 0x0003000A,
	TextureFormat16bitNorm = 0x0003000B,
	TextureCompressionAstcHdr = 0x0003000C,
	MappablePrimaryBuffers = 0x0003000E,
	BufferBindingArray = 0x0003000F,
	UniformBufferAndStorageTextureArrayNonUniformIndexing = 0x00030010,
	// TODO: requires wgpu.h api change
	// AddressModeClampToZero = 0x00030011,
	// AddressModeClampToBorder = 0x00030012,
	// PolygonModeLine = 0x00030013,
	// PolygonModePoint = 0x00030014,
	// ConservativeRasterization = 0x00030015,
	// ClearTexture = 0x00030016,
	SpirvShaderPassthrough = 0x00030017,
	// Multiview = 0x00030018,
	VertexAttribute64bit = 0x00030019,
	TextureFormatNv12 = 0x0003001A,
	RayTracingAccelerationStructure = 0x0003001B,
	RayQuery = 0x0003001C,
	ShaderF64 = 0x0003001D,
	ShaderI16 = 0x0003001E,
	ShaderPrimitiveIndex = 0x0003001F,
	ShaderEarlyDepthTest = 0x00030020,
	Subgroup = 0x00030021,
	SubgroupVertex = 0x00030022,
	SubgroupBarrier = 0x00030023,
	TimestampQueryInsideEncoders = 0x00030024,
	TimestampQueryInsidePasses = 0x00030025,
}

FilterMode :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Nearest = 0x00000001,
	Linear = 0x00000002,
}

FrontFace :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	CCW = 0x00000001,
	CW = 0x00000002,
}

IndexFormat :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Uint16 = 0x00000001,
	Uint32 = 0x00000002,
}

LoadOp :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Load = 0x00000001,
	Clear = 0x00000002,
}

MapAsyncStatus :: enum i32 {
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	Error = 0x00000003,
	Aborted = 0x00000004,
	Unknown = 0x00000005,
}

MipmapFilterMode :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Nearest = 0x00000001,
	Linear = 0x00000002,
}

OptionalBool :: enum i32 {
	False = 0x00000000,
	True = 0x00000001,
	Undefined = 0x00000002,
}

PopErrorScopeStatus :: enum i32 {
	/**
	 * `0x00000001`.
	 * The error scope stack was successfully popped and a result was reported.
	 */
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	/**
	 * `0x00000003`.
	 * The error scope stack could not be popped, because it was empty.
	 */
	EmptyStack = 0x00000003,
}

PowerPreference :: enum i32 {
	/**
	 * `0x00000000`.
	 * No preference. (See also @ref SentinelValues.)
	 */
	Undefined = 0x00000000,
	LowPower = 0x00000001,
	HighPerformance = 0x00000002,
}

/**
 * Describes when and in which order frames are presented on the screen when `::wgpuSurfacePresent` is called.
 */
PresentMode :: enum i32 {
	/**
	 * `0x00000000`.
	 * Present mode is not specified. Use the default.
	 */
	Undefined = 0x00000000,
	/**
	 * `0x00000001`.
	 * The presentation of the image to the user waits for the next vertical blanking period to update in a first-in, first-out manner.
	 * Tearing cannot be observed and frame-loop will be limited to the display's refresh rate.
	 * This is the only mode that's always available.
	 */
	Fifo = 0x00000001,
	/**
	 * `0x00000002`.
	 * The presentation of the image to the user tries to wait for the next vertical blanking period but may decide to not wait if a frame is presented late.
	 * Tearing can sometimes be observed but late-frame don't produce a full-frame stutter in the presentation.
	 * This is still a first-in, first-out mechanism so a frame-loop will be limited to the display's refresh rate.
	 */
	FifoRelaxed = 0x00000002,
	/**
	 * `0x00000003`.
	 * The presentation of the image to the user is updated immediately without waiting for a vertical blank.
	 * Tearing can be observed but latency is minimized.
	 */
	Immediate = 0x00000003,
	/**
	 * `0x00000004`.
	 * The presentation of the image to the user waits for the next vertical blanking period to update to the latest provided image.
	 * Tearing cannot be observed and a frame-loop is not limited to the display's refresh rate.
	 */
	Mailbox = 0x00000004,
}

PrimitiveTopology :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	PointList = 0x00000001,
	LineList = 0x00000002,
	LineStrip = 0x00000003,
	TriangleList = 0x00000004,
	TriangleStrip = 0x00000005,
}

QueryType :: enum i32 {
	// WebGPU.
	Occlusion = 0x00000000,
	Timestamp = 0x00000001,

	// Native.
	PipelineStatistics = 0x00030000,
}

QueueWorkDoneStatus :: enum i32 {
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	Error = 0x00000003,
	Unknown = 0x00000004,
}

RequestAdapterStatus :: enum i32 {
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	Unavailable = 0x00000003,
	Error = 0x00000004,
	Unknown = 0x00000005,
}

RequestDeviceStatus :: enum i32 {
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	Error = 0x00000003,
	Unknown = 0x00000004,
}

SType :: enum i32 {
	// WebGPU.
	ShaderSourceSPIRV = 0x00000001,
	ShaderSourceWGSL = 0x00000002,
	RenderPassMaxDrawCount = 0x00000003,
	SurfaceSourceMetalLayer = 0x00000004,
	SurfaceSourceWindowsHWND = 0x00000005,
	SurfaceSourceXlibWindow = 0x00000006,
	SurfaceSourceWaylandSurface = 0x00000007,
	SurfaceSourceAndroidNativeWindow = 0x00000008,
	SurfaceSourceXCBWindow = 0x00000009,

	// Native.
	DeviceExtras = 0x00030001,
	NativeLimits = 0x00030002,
	PipelineLayoutExtras = 0x00030003,
	ShaderModuleGLSLDescriptor = 0x00030004,
	InstanceExtras = 0x00030006,
	BindGroupEntryExtras = 0x00030007,
	BindGroupLayoutEntryExtras = 0x00030008,
	QuerySetDescriptorExtras = 0x00030009,
	SurfaceConfigurationExtras = 0x0003000A,
}

SamplerBindingType :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates that this @ref SamplerBindingLayout member of
	 * its parent @ref BindGroupLayoutEntry is not used.
	 * (See also @ref SentinelValues.)
	 */
	BindingNotUsed = 0x00000000,
	/**
	 * `0x00000001`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000001,
	Filtering = 0x00000002,
	NonFiltering = 0x00000003,
	Comparison = 0x00000004,
}

/**
 * Status code returned (synchronously) from many operations. Generally
 * indicates an invalid input like an unknown enum value or @ref OutStructChainError.
 * Read the function's documentation for specific error conditions.
 */
Status :: enum i32 {
	Success = 0x00000001,
	Error = 0x00000002,
}

StencilOperation :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Keep = 0x00000001,
	Zero = 0x00000002,
	Replace = 0x00000003,
	Invert = 0x00000004,
	IncrementClamp = 0x00000005,
	DecrementClamp = 0x00000006,
	IncrementWrap = 0x00000007,
	DecrementWrap = 0x00000008,
}

StorageTextureAccess :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates that this @ref StorageTextureBindingLayout member of
	 * its parent @ref BindGroupLayoutEntry is not used.
	 * (See also @ref SentinelValues.)
	 */
	BindingNotUsed = 0x00000000,
	/**
	 * `0x00000001`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000001,
	WriteOnly = 0x00000002,
	ReadOnly = 0x00000003,
	ReadWrite = 0x00000004,
}

StoreOp :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	Store = 0x00000001,
	Discard = 0x00000002,
}

/**
 * The status enum for `SurfaceGetCurrentTexture`.
 */
SurfaceGetCurrentTextureStatus :: enum i32 {
	/**
	 * `0x00000001`.
	 * Yay! Everything is good and we can render this frame.
	 */
	SuccessOptimal = 0x00000001,
	/**
	 * `0x00000002`.
	 * Still OK - the surface can present the frame, but in a suboptimal way. The surface may need reconfiguration.
	 */
	SuccessSuboptimal = 0x00000002,
	/**
	 * `0x00000003`.
	 * Some operation timed out while trying to acquire the frame.
	 */
	Timeout = 0x00000003,
	/**
	 * `0x00000004`.
	 * The surface is too different to be used, compared to when it was originally created.
	 */
	Outdated = 0x00000004,
	/**
	 * `0x00000005`.
	 * The connection to whatever owns the surface was lost.
	 */
	Lost = 0x00000005,
	/**
	 * `0x00000006`.
	 * The system ran out of memory.
	 */
	OutOfMemory = 0x00000006,
	/**
	 * `0x00000007`.
	 * The @ref WGPUDevice configured on the @ref WGPUSurface was lost.
	 */
	DeviceLost = 0x00000007,
	/**
	 * `0x00000008`.
	 * The surface is not configured, or there was an @ref OutStructChainError.
	 */
	Error = 0x00000008,
}

TextureAspect :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	All = 0x00000001,
	StencilOnly = 0x00000002,
	DepthOnly = 0x00000003,
}

TextureDimension :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	_1D = 0x00000001,
	_2D = 0x00000002,
	_3D = 0x00000003,
}

TextureFormat :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	R8Unorm = 0x00000001,
	R8Snorm = 0x00000002,
	R8Uint = 0x00000003,
	R8Sint = 0x00000004,
	R16Uint = 0x00000005,
	R16Sint = 0x00000006,
	R16Float = 0x00000007,
	RG8Unorm = 0x00000008,
	RG8Snorm = 0x00000009,
	RG8Uint = 0x0000000A,
	RG8Sint = 0x0000000B,
	R32Float = 0x0000000C,
	R32Uint = 0x0000000D,
	R32Sint = 0x0000000E,
	RG16Uint = 0x0000000F,
	RG16Sint = 0x00000010,
	RG16Float = 0x00000011,
	RGBA8Unorm = 0x00000012,
	RGBA8UnormSrgb = 0x00000013,
	RGBA8Snorm = 0x00000014,
	RGBA8Uint = 0x00000015,
	RGBA8Sint = 0x00000016,
	BGRA8Unorm = 0x00000017,
	BGRA8UnormSrgb = 0x00000018,
	RGB10A2Uint = 0x00000019,
	RGB10A2Unorm = 0x0000001A,
	RG11B10Ufloat = 0x0000001B,
	RGB9E5Ufloat = 0x0000001C,
	RG32Float = 0x0000001D,
	RG32Uint = 0x0000001E,
	RG32Sint = 0x0000001F,
	RGBA16Uint = 0x00000020,
	RGBA16Sint = 0x00000021,
	RGBA16Float = 0x00000022,
	RGBA32Float = 0x00000023,
	RGBA32Uint = 0x00000024,
	RGBA32Sint = 0x00000025,
	Stencil8 = 0x00000026,
	Depth16Unorm = 0x00000027,
	Depth24Plus = 0x00000028,
	Depth24PlusStencil8 = 0x00000029,
	Depth32Float = 0x0000002A,
	Depth32FloatStencil8 = 0x0000002B,
	BC1RGBAUnorm = 0x0000002C,
	BC1RGBAUnormSrgb = 0x0000002D,
	BC2RGBAUnorm = 0x0000002E,
	BC2RGBAUnormSrgb = 0x0000002F,
	BC3RGBAUnorm = 0x00000030,
	BC3RGBAUnormSrgb = 0x00000031,
	BC4RUnorm = 0x00000032,
	BC4RSnorm = 0x00000033,
	BC5RGUnorm = 0x00000034,
	BC5RGSnorm = 0x00000035,
	BC6HRGBUfloat = 0x00000036,
	BC6HRGBFloat = 0x00000037,
	BC7RGBAUnorm = 0x00000038,
	BC7RGBAUnormSrgb = 0x00000039,
	ETC2RGB8Unorm = 0x0000003A,
	ETC2RGB8UnormSrgb = 0x0000003B,
	ETC2RGB8A1Unorm = 0x0000003C,
	ETC2RGB8A1UnormSrgb = 0x0000003D,
	ETC2RGBA8Unorm = 0x0000003E,
	ETC2RGBA8UnormSrgb = 0x0000003F,
	EACR11Unorm = 0x00000040,
	EACR11Snorm = 0x00000041,
	EACRG11Unorm = 0x00000042,
	EACRG11Snorm = 0x00000043,
	ASTC4x4Unorm = 0x00000044,
	ASTC4x4UnormSrgb = 0x00000045,
	ASTC5x4Unorm = 0x00000046,
	ASTC5x4UnormSrgb = 0x00000047,
	ASTC5x5Unorm = 0x00000048,
	ASTC5x5UnormSrgb = 0x00000049,
	ASTC6x5Unorm = 0x0000004A,
	ASTC6x5UnormSrgb = 0x0000004B,
	ASTC6x6Unorm = 0x0000004C,
	ASTC6x6UnormSrgb = 0x0000004D,
	ASTC8x5Unorm = 0x0000004E,
	ASTC8x5UnormSrgb = 0x0000004F,
	ASTC8x6Unorm = 0x00000050,
	ASTC8x6UnormSrgb = 0x00000051,
	ASTC8x8Unorm = 0x00000052,
	ASTC8x8UnormSrgb = 0x00000053,
	ASTC10x5Unorm = 0x00000054,
	ASTC10x5UnormSrgb = 0x00000055,
	ASTC10x6Unorm = 0x00000056,
	ASTC10x6UnormSrgb = 0x00000057,
	ASTC10x8Unorm = 0x00000058,
	ASTC10x8UnormSrgb = 0x00000059,
	ASTC10x10Unorm = 0x0000005A,
	ASTC10x10UnormSrgb = 0x0000005B,
	ASTC12x10Unorm = 0x0000005C,
	ASTC12x10UnormSrgb = 0x0000005D,
	ASTC12x12Unorm = 0x0000005E,
	ASTC12x12UnormSrgb = 0x0000005F,

	// Native.

	// From FeatureName.TextureFormat16bitNorm
	R16Unorm = 0x00030001,
	R16Snorm = 0x00030002,
	Rg16Unorm = 0x00030003,
	Rg16Snorm = 0x00030004,
	Rgba16Unorm = 0x00030005,
	Rgba16Snorm = 0x00030006,
	// From FeatureName.TextureFormatNv12
	NV12 = 0x00030007,
}

TextureSampleType :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates that this @ref TextureBindingLayout member of
	 * its parent @ref BindGroupLayoutEntry is not used.
	 * (See also @ref SentinelValues.)
	 */
	BindingNotUsed = 0x00000000,
	/**
	 * `0x00000001`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000001,
	Float = 0x00000002,
	UnfilterableFloat = 0x00000003,
	Depth = 0x00000004,
	Sint = 0x00000005,
	Uint = 0x00000006,
}

TextureViewDimension :: enum i32 {
	/**
	 * `0x00000000`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000000,
	_1D = 0x00000001,
	_2D = 0x00000002,
	_2DArray = 0x00000003,
	Cube = 0x00000004,
	CubeArray = 0x00000005,
	_3D = 0x00000006,
}

VertexFormat :: enum i32 {
	Uint8 = 0x00000001,
	Uint8x2 = 0x00000002,
	Uint8x4 = 0x00000003,
	Sint8 = 0x00000004,
	Sint8x2 = 0x00000005,
	Sint8x4 = 0x00000006,
	Unorm8 = 0x00000007,
	Unorm8x2 = 0x00000008,
	Unorm8x4 = 0x00000009,
	Snorm8 = 0x0000000A,
	Snorm8x2 = 0x0000000B,
	Snorm8x4 = 0x0000000C,
	Uint16 = 0x0000000D,
	Uint16x2 = 0x0000000E,
	Uint16x4 = 0x0000000F,
	Sint16 = 0x00000010,
	Sint16x2 = 0x00000011,
	Sint16x4 = 0x00000012,
	Unorm16 = 0x00000013,
	Unorm16x2 = 0x00000014,
	Unorm16x4 = 0x00000015,
	Snorm16 = 0x00000016,
	Snorm16x2 = 0x00000017,
	Snorm16x4 = 0x00000018,
	Float16 = 0x00000019,
	Float16x2 = 0x0000001A,
	Float16x4 = 0x0000001B,
	Float32 = 0x0000001C,
	Float32x2 = 0x0000001D,
	Float32x3 = 0x0000001E,
	Float32x4 = 0x0000001F,
	Uint32 = 0x00000020,
	Uint32x2 = 0x00000021,
	Uint32x3 = 0x00000022,
	Uint32x4 = 0x00000023,
	Sint32 = 0x00000024,
	Sint32x2 = 0x00000025,
	Sint32x3 = 0x00000026,
	Sint32x4 = 0x00000027,
	Unorm10_10_10_2 = 0x00000028,
	Unorm8x4BGRA = 0x00000029,
}

VertexStepMode :: enum i32 {
	/**
	 * `0x00000000`.
	 * This @ref VertexBufferLayout is a "hole" in the @ref VertexState `buffers` array.
	 * (See also @ref SentinelValues.)
	 */
	VertexBufferNotUsed = 0x00000000,
	/**
	 * `0x00000001`.
	 * Indicates no value is passed for this argument. See @ref SentinelValues.
	 */
	Undefined = 0x00000001,
	Vertex = 0x00000002,
	Instance = 0x00000003,
}

WGSLLanguageFeatureName :: enum i32 {
	ReadonlyAndReadwriteStorageTextures = 0x00000001,
	Packed4x8IntegerDotProduct = 0x00000002,
	UnrestrictedPointerParameters = 0x00000003,
	PointerCompositeAccess = 0x00000004,
}

/**
 * Status returned from a call to InstanceWaitAny.
 */
WaitStatus :: enum i32 {
	/**
	 * `0x00000001`.
	 * At least one Future completed successfully.
	 */
	Success = 0x00000001,
	/**
	 * `0x00000002`.
	 * No Futures completed within the timeout.
	 */
	TimedOut = 0x00000002,
	/**
	 * `0x00000003`.
	 * A @ref Timed-Wait was performed when InstanceFeaturesl.timedWaitAnyEnable is false.
	 */
	UnsupportedTimeout = 0x00000003,
	/**
	 * `0x00000004`.
	 * The number of futures waited on in a @ref Timed-Wait is greater than the supported InstanceFeatures.timedWaitAnyMaxCount.
	 */
	UnsupportedCount = 0x00000004,
	/**
	 * `0x00000005`.
	 * An invalid wait was performed with @ref Mixed-Sources.
	 */
	UnsupportedMixedSources = 0x00000005,
}

BufferUsage :: enum i32 {
	MapRead = 0x00000000,
	MapWrite = 0x00000001,
	CopySrc = 0x00000002,
	CopyDst = 0x00000003,
	Index = 0x00000004,
	Vertex = 0x00000005,
	Uniform = 0x00000006,
	Storage = 0x00000007,
	Indirect = 0x00000008,
	QueryResolve = 0x00000009,
}
BufferUsageFlags :: bit_set[BufferUsage; Flags]
BufferUsageFlags_None :: BufferUsageFlags{}

ColorWriteMask :: enum i32 {
	Red = 0x00000000,
	Green = 0x00000001,
	Blue = 0x00000002,
	Alpha = 0x00000003,
}
ColorWriteMaskFlags :: bit_set[ColorWriteMask; Flags]
ColorWriteMaskFlags_None :: ColorWriteMaskFlags{}
ColorWriteMaskFlags_All :: ColorWriteMaskFlags{ .Red, .Green, .Blue, .Alpha }

MapMode :: enum i32 {
	Read = 0x00000000,
	Write = 0x00000001,
}
MapModeFlags :: bit_set[MapMode; Flags]
MapModeFlags_None :: MapModeFlags{}

ShaderStage :: enum i32 {
	Vertex = 0x00000000,
	Fragment = 0x00000001,
	Compute = 0x00000002,
}
ShaderStageFlags :: bit_set[ShaderStage; Flags]
ShaderStageFlags_None :: ShaderStageFlags{}

TextureUsage :: enum i32 {
	CopySrc = 0x00000000,
	CopyDst = 0x00000001,
	TextureBinding = 0x00000002,
	StorageBinding = 0x00000003,
	RenderAttachment = 0x00000004,
}
TextureUsageFlags :: bit_set[TextureUsage; Flags]
TextureUsageFlags_None :: TextureUsageFlags{}

Proc :: distinct rawptr

/**
 * @param message
 * This parameter is @ref PassedWithoutOwnership.
 */
BufferMapCallback :: #type proc "c" (status: MapAsyncStatus, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)
/**
 * @param compilationInfo
 * This parameter is @ref PassedWithoutOwnership.
 */
CompilationInfoCallback :: #type proc "c" (status: CompilationInfoRequestStatus, compilationInfo: /* const */ ^CompilationInfo, /* NULLABLE */ userdata1, userdata2: rawptr)
 /**
  * @param pipeline
  * This parameter is @ref PassedWithOwnership.
  */
CreateComputePipelineAsyncCallback :: #type proc "c" (status: CreatePipelineAsyncStatus, pipeline: ComputePipeline, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)
 /**
  * @param pipeline
  * This parameter is @ref PassedWithOwnership.
  */
CreateRenderPipelineAsyncCallback :: #type proc "c" (status: CreatePipelineAsyncStatus, pipeline: RenderPipeline, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)
 /**
  * @param device
  * Reference to the device which was lost. If, and only if, the `reason` is @ref DeviceLostReason.FailedCreation, this is a non-null pointer to a null @ref Device.
  * This parameter is @ref PassedWithoutOwnership.
  *
  * @param message
  * This parameter is @ref PassedWithoutOwnership.
  */
DeviceLostCallback :: #type proc "c" (device: /* const */ ^Device, reason: DeviceLostReason, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)
 /**
  * @param status
  * See @ref WGPUPopErrorScopeStatus.
  *
  * @param type
  * The type of the error caught by the scope, or @ref ErrorType.NoError if there was none.
  * If the `status` is not @ref PopErrorScopeStatus.Success, this is @ref ErrorType.NoError.
  *
  * @param message
  * If the `type` is not @ref ErrorType.NoError, this is a non-empty @ref LocalizableHumanReadableMessageString;
  * otherwise, this is an empty string.
  * This parameter is @ref PassedWithoutOwnership.
  */
PopErrorScopeCallback :: #type proc "c" (status: PopErrorScopeStatus, type: ErrorType, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)
QueueWorkDoneCallback :: #type proc "c" (status: QueueWorkDoneStatus, /* NULLABLE */ userdata1, userdata2: rawptr)
 /**
  * @param adapter
  * This parameter is @ref PassedWithOwnership.
  *
  * @param message
  * This parameter is @ref PassedWithoutOwnership.
  */
RequestAdapterCallback :: #type proc "c" (status: RequestAdapterStatus, adapter: Adapter, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)
 /**
  * @param device
  * This parameter is @ref PassedWithOwnership.
  *
  * @param message
  * This parameter is @ref PassedWithoutOwnership.
  */
RequestDeviceCallback :: #type proc "c" (status: RequestDeviceStatus, device: Device, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)
 /**
  * @param device
  * This parameter is @ref PassedWithoutOwnership.
  *
  * @param message
  * This parameter is @ref PassedWithoutOwnership.
  */
UncapturedErrorCallback :: #type proc "c" (device: /* const */ ^Device, type: ErrorType, message: StringView, /* NULLABLE */ userdata1, userdata2: rawptr)

ChainedStruct :: struct {
	next: /* const */ ^ChainedStruct,
	sType: SType,
}

ChainedStructOut :: struct {
	next: ^ChainedStructOut,
	sType: SType,
}

BufferMapCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: BufferMapCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

CompilationInfoCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: CompilationInfoCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

CreateComputePipelineAsyncCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: CreateComputePipelineAsyncCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

CreateRenderPipelineAsyncCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: CreateRenderPipelineAsyncCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

DeviceLostCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: DeviceLostCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

PopErrorScopeCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: PopErrorScopeCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

QueueWorkDoneCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: QueueWorkDoneCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

RequestAdapterCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: RequestAdapterCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

RequestDeviceCallbackInfo :: struct {
	nextInChain : /* const */ ^ChainedStruct,
	mode: CallbackMode,
    callback: RequestDeviceCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

UncapturedErrorCallbackInfo :: struct {
    nextInChain : /* const */ ^ChainedStruct,
    callback: UncapturedErrorCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

AdapterInfo :: struct {
	nextInChain: ^ChainedStructOut,
	/**
	 * This is an \ref OutputString.
	 */
	vendor: StringView,
	/**
	 * This is an \ref OutputString.
	 */
	architecture: StringView,
	/**
	 * This is an \ref OutputString.
	 */
	device: StringView,
	description: StringView,
	/**
	 * This is an \ref OutputString.
	 */
	backendType: BackendType,
	adapterType: AdapterType,
	vendorID: u32,
	deviceID: u32,
}
when ODIN_OS == .JS {
	#assert(int(BackendType.WebGPU) == 2)
	#assert(offset_of(AdapterInfo, backendType) == 36)

	#assert(int(AdapterType.Unknown) == 4)
	#assert(offset_of(AdapterInfo, adapterType) == 40)
}

BindGroupEntry :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	binding: u32,
	/* NULLABLE */ buffer: Buffer,
	offset: u64,
	size: u64,
	/* NULLABLE */ sampler: Sampler,
	/* NULLABLE */ textureView: TextureView,
}

BlendComponent :: struct {
	operation: BlendOperation,
	srcFactor: BlendFactor,
	dstFactor: BlendFactor,
}

BufferBindingLayout :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	type: BufferBindingType,
	hasDynamicOffset: b32,
	minBindingSize: u64,
}

BufferDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	usage: BufferUsageFlags,
	size: u64,
	mappedAtCreation: b32,
}

Color :: [4]f64

CommandBufferDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
}

CommandEncoderDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
}

CompilationMessage :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * A @ref LocalizableHumanReadableMessageString.
	 *
	 * This is an \ref OutputString.
	 */
	message: StringView,
	/**
	 * Severity level of the message.
	 */
	type: CompilationMessageType,
	/**
	 * Line number where the message is attached, starting at 1.
	 */
	lineNum: u64,
	/**
	 * Offset in UTF-8 code units (bytes) from the beginning of the line, starting at 1.
	 */
	linePos: u64,
	/**
	 * Offset in UTF-8 code units (bytes) from the beginning of the shader code, starting at 0.
	 */
	offset: u64,
	/**
	 * Length in UTF-8 code units (bytes) of the span the message corresponds to.
	 */
	length: u64,
}

ComputePassTimestampWrites :: struct {
	querySet: QuerySet,
	beginningOfPassWriteIndex: u32,
	endOfPassWriteIndex: u32,
}

ConstantEntry :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	key: StringView,
	value: f64,
}

Extent3D :: struct {
	width: u32,
	height: u32,
	depthOrArrayLayers: u32,
}

/**
 * Opaque handle to an asynchronous operation. See @ref Asynchronous-Operations for more information.
 */
Future :: struct {
	/**
	 * Opaque id of the @ref Future
	 */
	id: u64,
}

/**
 * Features enabled on the Instance
 */
InstanceCapabilities :: struct {
    /** This struct chain is used as mutable in some places and immutable in others. */
    nextInChain: ^ChainedStructOut,
    /**
     * Enable use of InstanceWaitAny with `timeoutNS > 0`.
     */
    timedWaitAnyEnable: b32,
    /**
     * The maximum number @ref FutureWaitInfo supported in a call to InstanceWaitAny with `timeoutNS > 0`.
     */
    timedWaitAnyMaxCount: uint,
}

Limits :: struct {
	/** This struct chain is used as mutable in some places and immutable in others. */
	nextInChain: ^ChainedStructOut,
	maxTextureDimension1D: u32,
	maxTextureDimension2D: u32,
	maxTextureDimension3D: u32,
	maxTextureArrayLayers: u32,
	maxBindGroups: u32,
	maxBindGroupsPlusVertexBuffers: u32,
	maxBindingsPerBindGroup: u32,
	maxDynamicUniformBuffersPerPipelineLayout: u32,
	maxDynamicStorageBuffersPerPipelineLayout: u32,
	maxSampledTexturesPerShaderStage: u32,
	maxSamplersPerShaderStage: u32,
	maxStorageBuffersPerShaderStage: u32,
	maxStorageTexturesPerShaderStage: u32,
	maxUniformBuffersPerShaderStage: u32,
	maxUniformBufferBindingSize: u64,
	maxStorageBufferBindingSize: u64,
	minUniformBufferOffsetAlignment: u32,
	minStorageBufferOffsetAlignment: u32,
	maxVertexBuffers: u32,
	maxBufferSize: u64,
	maxVertexAttributes: u32,
	maxVertexBufferArrayStride: u32,
	maxInterStageShaderVariables: u32,
	maxColorAttachments: u32,
	maxColorAttachmentBytesPerSample: u32,
	maxComputeWorkgroupStorageSize: u32,
	maxComputeInvocationsPerWorkgroup: u32,
	maxComputeWorkgroupSizeX: u32,
	maxComputeWorkgroupSizeY: u32,
	maxComputeWorkgroupSizeZ: u32,
	maxComputeWorkgroupsPerDimension: u32,
}

MultisampleState :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	count: u32,
	mask: u32,
	alphaToCoverageEnabled: b32,
}

Origin3D :: struct {
	x: u32,
	y: u32,
	z: u32,
}

PipelineLayoutDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	bindGroupLayoutCount: uint,
	bindGroupLayouts: /* const */ [^]BindGroupLayout `fmt:"v,bindGroupLayoutCount"`,
}

PrimitiveState :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	topology: PrimitiveTopology,
	stripIndexFormat: IndexFormat,
	frontFace: FrontFace,
	cullMode: CullMode,
	unclippedDepth: b32,
}

QuerySetDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	type: QueryType,
	count: u32,
}

QueueDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
}

RenderBundleDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
}

RenderBundleEncoderDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	colorFormatCount: uint,
	colorFormats: /* const */ [^]TextureFormat `fmt:"v,colorFormatCount"`,
	depthStencilFormat: TextureFormat,
	sampleCount: u32,
	depthReadOnly: b32,
	stencilReadOnly: b32,
}

RenderPassDepthStencilAttachment :: struct {
	view: TextureView,
	depthLoadOp: LoadOp,
	depthStoreOp: StoreOp,
	depthClearValue: f32,
	depthReadOnly: b32,
	stencilLoadOp: LoadOp,
	stencilStoreOp: StoreOp,
	stencilClearValue: u32,
	stencilReadOnly: b32,
}

RenderPassDescriptorMaxDrawCount :: struct {
	using chain: ChainedStruct,
	maxDrawCount: u64,
}

RenderPassTimestampWrites :: struct {
	querySet: QuerySet,
	beginningOfPassWriteIndex: u32,
	endOfPassWriteIndex: u32,
}

RequestAdapterOptions :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * "Feature level" for the adapter request. If an adapter is returned, it must support the features and limits in the requested feature level.
	 *
	 * Implementations may ignore @ref FeatureLevel.Compatibility and provide @ref FeatureLevel.Core instead. @ref FeatureLevel.Core is the default in the JS API, but in C, this field is **required** (must not be undefined).
	 */
	featureLevel: FeatureLevel,
	powerPreference: PowerPreference,
	/**
	 * If true, requires the adapter to be a "fallback" adapter as defined by the JS spec.
	 * If this is not possible, the request returns null.
	 */
	forceFallbackAdapter: b32,
	/**
	 * If set, requires the adapter to have a particular backend type.
	 * If this is not possible, the request returns null.
	 */
	backendType: BackendType,
	/**
	 * If set, requires the adapter to be able to output to a particular surface.
	 * If this is not possible, the request returns null.
	 */
	/* NULLABLE */ compatibleSurface: Surface,
}

SamplerBindingLayout :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	type: SamplerBindingType,
}

SamplerDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	addressModeU: AddressMode,
	addressModeV: AddressMode,
	addressModeW: AddressMode,
	magFilter: FilterMode,
	minFilter: FilterMode,
	mipmapFilter: MipmapFilterMode,
	lodMinClamp: f32,
	lodMaxClamp: f32,
	compare: CompareFunction,
	maxAnisotropy: u16,
}

ShaderModuleDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
}

ShaderSourceSPIRV :: struct {
	using chain: ChainedStruct,
	codeSize: u32,
	code: /* const */ [^]u32 `fmt:"v,codeSize"`,
}

ShaderSourceWGSL :: struct {
	using chain: ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	code: StringView,
}

StencilFaceState :: struct {
	compare: CompareFunction,
	failOp: StencilOperation,
	depthFailOp: StencilOperation,
	passOp: StencilOperation,
}

StorageTextureBindingLayout :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	access: StorageTextureAccess,
	format: TextureFormat,
	viewDimension: TextureViewDimension,
}

SupportedFeatures :: struct {
	featureCount: uint,
	features: /* const */ [^]FeatureName `fmt:"v,featureCount"`,
}

SupportedWGSLLanguageFeatures :: struct {
    featureCount: uint,
    features: /* const */ [^]WGSLLanguageFeatureName `fmt:"v,featureCount"`,
}

/**
 * Filled by `SurfaceGetCapabilities` with what's supported for `SurfaceConfigure` for a pair of @ref Surface and @ref Adapter.
 */
SurfaceCapabilities :: struct {
	nextInChain: ^ChainedStructOut,
	/**
	 * The bit set of supported @ref TextureUsage bits.
	 * Guaranteed to contain @ref TextureUsage.RenderAttachment.
	 */
	usages: TextureUsageFlags,
	/**
	 * A list of supported @ref TextureFormat values, in order of preference.
	 */
	formatCount: uint,
	formats: /* const */ [^]TextureFormat `fmt:"v,formatCount"`,
	/**
	 * A list of supported @ref PresentMode values.
	 * Guaranteed to contain @ref PresentMode.Fifo.
	 */
	presentModeCount: uint,
	presentModes: /* const */ [^]PresentMode `fmt:"v,presentModeCount"`,
	/**
	 * A list of supported @ref CompositeAlphaMode values.
	 * @ref CompositeAlphaMode.Auto will be an alias for the first element and will never be present in this array.
	 */
	alphaModeCount: uint,
	alphaModes: /* const */ [^]CompositeAlphaMode `fmt:"v,alphaModeCount"`,
}
when ODIN_OS == .JS {
	#assert(offset_of(SurfaceCapabilities, formatCount) == 12)
	#assert(offset_of(SurfaceCapabilities, formats) == 16)

	#assert(offset_of(SurfaceCapabilities, presentModeCount) == 20)
	#assert(offset_of(SurfaceCapabilities, presentModes) == 24)

	#assert(offset_of(SurfaceCapabilities, alphaModeCount) == 28)
	#assert(offset_of(SurfaceCapabilities, alphaModes) == 32)
}

/**
 * Options to `SurfaceConfigure` for defining how a @ref Surface will be rendered to and presented to the user.
 * See @ref Surface-Configuration for more details.
 */
SurfaceConfiguration :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	device: Device,
	format: TextureFormat,
	usage: TextureUsageFlags,
	width: u32,
	height: u32,
	viewFormatCount: uint,
	viewFormats: /* const */ [^]TextureFormat `fmt:"v,viewFormatCount"`,
	alphaMode: CompositeAlphaMode,
	presentMode: PresentMode,
}

/**
 * The root descriptor for the creation of an @ref Surface with `InstanceCreateSurface`.
 * It isn't sufficient by itself and must have one of the `SurfaceSource*` in its chain.
 * See @ref Surface-Creation for more details.
 */
SurfaceDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * Label used to refer to the object.
	 *
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
}

/**
 * Chained in @ref SurfaceDescriptor to make an @ref Surface wrapping an Android [`ANativeWindow`](https://developer.android.com/ndk/reference/group/a-native-window).
 */
SurfaceSourceAndroidNativeWindow :: struct {
	using chain: ChainedStruct,
	/**
	 * The pointer to the [`ANativeWindow`](https://developer.android.com/ndk/reference/group/a-native-window) that will be wrapped by the @ref Surface.
	 */
	window: rawptr,
}

/**
 * Chained in @ref SurfaceDescriptor to make an @ref Surface wrapping a [`CAMetalLayer`](https://developer.apple.com/documentation/quartzcore/cametallayer?language=objc).
 */
SurfaceSourceMetalLayer :: struct {
	using chain: ChainedStruct,
	/**
	 * The pointer to the [`CAMetalLayer`](https://developer.apple.com/documentation/quartzcore/cametallayer?language=objc) that will be wrapped by the @ref Surface.
	 */
	layer: rawptr,
}

/**
 * Chained in @ref SurfaceDescriptor to make an @ref Surface wrapping a [Wayland](https://wayland.freedesktop.org/) [`wl_surface`](https://wayland.freedesktop.org/docs/html/apa.html#protocol-spec-wl_surface).
 */
SurfaceSourceWaylandSurface :: struct {
	using chain: ChainedStruct,
	/**
	 * A [`wl_display`](https://wayland.freedesktop.org/docs/html/apa.html#protocol-spec-wl_display) for this Wayland instance.
	 */
	display: rawptr,
	/**
	 * A [`wl_surface`](https://wayland.freedesktop.org/docs/html/apa.html#protocol-spec-wl_surface) that will be wrapped by the @ref Surface
	 */
	surface: rawptr,
}

/**
 * Chained in @ref SurfaceDescriptor to make an @ref Surface wrapping a Windows [`HWND`](https://learn.microsoft.com/en-us/windows/apps/develop/ui-input/retrieve-hwnd).
 */
SurfaceSourceWindowsHWND :: struct {
	using chain: ChainedStruct,
	/**
	 * The [`HINSTANCE`](https://learn.microsoft.com/en-us/windows/win32/learnwin32/winmain--the-application-entry-point) for this application.
	 * Most commonly `GetModuleHandle(nullptr)`.
	 */
	hinstance: rawptr,
	/**
	 * The [`HWND`](https://learn.microsoft.com/en-us/windows/apps/develop/ui-input/retrieve-hwnd) that will be wrapped by the @ref Surface.
	 */
	hwnd: rawptr,
}

/**
 * Chained in @ref SurfaceDescriptor to make an @ref Surface wrapping an [XCB](https://xcb.freedesktop.org/) `xcb_window_t`.
 */
SurfaceSourceXCBWindow :: struct {
	using chain: ChainedStruct,
	/**
	 * The `xcb_connection_t` for the connection to the X server.
	 */
	connection: rawptr,
	/**
	 * The `xcb_window_t` for the window that will be wrapped by the @ref Surface.
	 */
	window: u32,
}

/**
 * Chained in @ref SurfaceDescriptor to make an @ref Surface wrapping an [Xlib](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html) `Window`.
 */
SurfaceSourceXlibWindow :: struct {
	using chain: ChainedStruct,
	/**
	 * A pointer to the [`Display`](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html#Opening_the_Display) connected to the X server.
	 */
	display: rawptr,
	/**
	 * The [`Window`](https://www.x.org/releases/current/doc/libX11/libX11/libX11.html#Creating_Windows) that will be wrapped by the @ref Surface.
	 */
	window: u64,
}

/**
 * Queried each frame from a @ref Surface to get a @ref Texture to render to along with some metadata.
 * See @ref Surface-Presenting for more details.
 */
SurfaceTexture :: struct {
	nextInChain: ^ChainedStructOut,
	/**
	 * The @ref Texture representing the frame that will be shown on the surface.
	 * It is @ref ReturnedWithOwnership from @ref SurfaceGetCurrentTexture.
	 */
	texture: Texture,
	/**
	 * Whether the call to `SurfaceGetCurrentTexture` succeeded and a hint as to why it might not have.
	 */
	status: SurfaceGetCurrentTextureStatus,
}

TexelCopyBufferLayout :: struct {
    offset: u64,
    bytesPerRow: u32,
    rowsPerImage: u32,
}

TextureBindingLayout :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	sampleType: TextureSampleType,
	viewDimension: TextureViewDimension,
	multisampled: b32,
}

TextureViewDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	format: TextureFormat,
	dimension: TextureViewDimension,
	baseMipLevel: u32,
	mipLevelCount: u32,
	baseArrayLayer: u32,
	arrayLayerCount: u32,
	aspect: TextureAspect,
	usage: TextureUsageFlags,
}

VertexAttribute :: struct {
	format: VertexFormat,
	offset: u64,
	shaderLocation: u32,
}

BindGroupDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	layout: BindGroupLayout,
	entryCount: uint,
	entries: /* const */ [^]BindGroupEntry `fmt:"v,entryCount"`,
}

BindGroupLayoutEntry :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	binding: u32,
	visibility: ShaderStageFlags,
	buffer: BufferBindingLayout,
	sampler: SamplerBindingLayout,
	texture: TextureBindingLayout,
	storageTexture: StorageTextureBindingLayout,
}

BlendState :: struct {
	color: BlendComponent,
	alpha: BlendComponent,
}

CompilationInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	messageCount: uint,
	messages: /* const */ [^]CompilationMessage `fmt:"v,messageCount"`,
}

ComputePassDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	/* NULLABLE */ timestampWrites: /* const */ ^ComputePassTimestampWrites,
}

DepthStencilState :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	format: TextureFormat,
	depthWriteEnabled: OptionalBool,
	depthCompare: CompareFunction,
	stencilFront: StencilFaceState,
	stencilBack: StencilFaceState,
	stencilReadMask: u32,
	stencilWriteMask: u32,
	depthBias: i32,
	depthBiasSlopeScale: f32,
	depthBiasClamp: f32,
}

DeviceDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	requiredFeatureCount: uint,
	requiredFeatures: /* const */ [^]FeatureName`fmt:"v,requiredFeatureCount"`,
	/* NULLABLE */ requiredLimits: /* const */ ^Limits,
	defaultQueue: QueueDescriptor,
	deviceLostCallbackInfo: DeviceLostCallbackInfo,
	uncapturedErrorCallbackInfo: UncapturedErrorCallbackInfo,
}
when ODIN_OS == .JS {
	#assert(offset_of(DeviceDescriptor, deviceLostCallback.callback) == 32)
}

/**
 * Struct holding a future to wait on, and a `completed` boolean flag.
 */
FutureWaitInfo :: struct {
	/**
	 * The future to wait on.
	 */
	future: Future,
	/**
	 * Whether or not the future completed.
	 */
	completed: b32,
}

InstanceDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * Instance features to enable
	 */
	features: InstanceCapabilities,
}

ProgrammableStageDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	module: ShaderModule,
	/**
	 * This is a \ref NullableInputString.
	 */
	entryPoint: StringView,
	constantCount: uint,
	constants: /* const */ [^]ConstantEntry `fmt:"v,constantCount"`,
}

RenderPassColorAttachment :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/* NULLABLE */ view: TextureView,
	depthSlice: u32,
	/* NULLABLE */ resolveTarget: TextureView,
	loadOp: LoadOp,
	storeOp: StoreOp,
	clearValue: Color,
}
when ODIN_OS == .JS {
	#assert(size_of(RenderPassColorAttachment) == 56)
	#assert(offset_of(RenderPassColorAttachment, view) == 4)
	#assert(offset_of(RenderPassColorAttachment, depthSlice) == 8)
	#assert(offset_of(RenderPassColorAttachment, resolveTarget) == 12)
	#assert(offset_of(RenderPassColorAttachment, loadOp) == 16)
	#assert(offset_of(RenderPassColorAttachment, storeOp) == 20)
	#assert(offset_of(RenderPassColorAttachment, clearValue) == 24)
}

TexelCopyBufferInfo :: struct {
    layout: TexelCopyBufferLayout,
    buffer: Buffer,
}

TexelCopyTextureInfo :: struct {
    texture: Texture,
    mipLevel: u32,
    origin: Origin3D,
    aspect: TextureAspect,
}

TextureDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	usage: TextureUsageFlags,
	dimension: TextureDimension,
	size: Extent3D,
	format: TextureFormat,
	mipLevelCount: u32,
	sampleCount: u32,
	viewFormatCount: uint,
	viewFormats: /* const */ [^]TextureFormat `fmt:"v,viewFormatCount"`,
}

VertexBufferLayout :: struct {
	/**
	 * The step mode for the vertex buffer. If @ref VertexStepMode.VertexBufferNotUsed,
	 * indicates a "hole" in the parent @ref VertexState `buffers` array:
	 * the pipeline does not use a vertex buffer at this `location`.
	 */
	stepMode: VertexStepMode,
	arrayStride: u64,
	attributeCount: uint,
	attributes: /* const */ [^]VertexAttribute `fmt:"v,attributeCount"`,
}

BindGroupLayoutDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	entryCount: uint,
	entries: /* const */ [^]BindGroupLayoutEntry `fmt:"v,entryCount"`,
}

ColorTargetState :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * The texture format of the target. If @ref TextureFormat.Undefined,
	 * indicates a "hole" in the parent @ref FragmentState `targets` array:
	 * the pipeline does not output a value at this `location`.
	 */
	format: TextureFormat,
	/* NULLABLE */ blend: /* const */ ^BlendState,
	writeMask: ColorWriteMaskFlags,
}

ComputePipelineDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	/* NULLABLE */ layout: PipelineLayout,
	compute: ProgrammableStageDescriptor,
}

RenderPassDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	colorAttachmentCount: uint,
	colorAttachments: /* const */ [^]RenderPassColorAttachment `fmt:"v,colorAttachmentCount"`,
	/* NULLABLE */ depthStencilAttachment: /* const */ ^RenderPassDepthStencilAttachment,
	/* NULLABLE */ occlusionQuerySet: QuerySet,
	/* NULLABLE */ timestampWrites: /* const */ ^RenderPassTimestampWrites,
}

VertexState :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	module: ShaderModule,
	/**
	 * This is a \ref NullableInputString.
	 */
	entryPoint: StringView,
	constantCount: uint,
	constants: /* const */ [^]ConstantEntry `fmt:"v,constantCount"`,
	bufferCount: uint,
	buffers: /* const */ [^]VertexBufferLayout `fmt:"v,bufferCount"`,
}

FragmentState :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	module: ShaderModule,
	/**
	 * This is a \ref NullableInputString.
	 */
	entryPoint: StringView,
	constantCount: uint,
	constants: /* const */ [^]ConstantEntry `fmt:"v,constantCount"`,
	targetCount: uint,
	targets: /* const */ [^]ColorTargetState `fmt:"v,targetCount"`,
}

RenderPipelineDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	/* NULLABLE */ layout: PipelineLayout,
	vertex: VertexState,
	primitive: PrimitiveState,
	/* NULLABLE */ depthStencil: /* const */ ^DepthStencilState,
	multisample: MultisampleState,
	/* NULLABLE */ fragment: /* const */ ^FragmentState,
}

@(link_prefix="wgpu", default_calling_convention="c")
foreign libwgpu {
	@(link_name="wgpuCreateInstance")
	RawCreateInstance :: proc(/* NULLABLE */ descriptor: /* const */ ^InstanceDescriptor = nil) -> Instance ---
	@(link_name="wgpuGetInstanceCapabilities")
	RawGetInstanceCapabilities :: proc(capabilities: ^InstanceCapabilities) -> Status ---
	GetProcAddress :: proc(procName: StringView) -> Proc ---

	// Methods of Adapter
	@(link_name="wgpuAdapterGetFeatures")
	RawAdapterGetFeatures :: proc(adapter: Adapter, features: ^SupportedFeatures) ---
	@(link_name="wgpuAdapterGetInfo")
	RawAdapterGetInfo :: proc(adapter: Adapter, info: ^AdapterInfo) ---
	@(link_name="wgpuAdapterGetLimits")
	RawAdapterGetLimits :: proc(adapter: Adapter, limits: ^Limits) -> Status ---
	AdapterHasFeature :: proc(adapter: Adapter, feature: FeatureName) -> b32 ---
	AdapterRequestDevice :: proc(adapter: Adapter, /* NULLABLE */ descriptor: /* const */ ^DeviceDescriptor, callbackInfo: RequestDeviceCallbackInfo) ---
	AdapterAddRef :: proc(adapter: Adapter) ---
	AdapterRelease :: proc(adapter: Adapter) ---

	// Procs of AdapterInfo
	AdapterInfoFreeMembers :: proc(adapterInfo: AdapterInfo) ---

	// Methods of BindGroup
	BindGroupSetLabel :: proc(bindGroup: BindGroup, label: StringView) ---
	BindGroupAddRef :: proc(bindGroup: BindGroup) ---
	BindGroupRelease :: proc(bindGroup: BindGroup) ---

	// Methods of BindGroupLayout
	BindGroupLayoutSetLabel :: proc(bindGroupLayout: BindGroupLayout, label: StringView) ---
	BindGroupLayoutAddRef :: proc(bindGroupLayout: BindGroupLayout) ---
	BindGroupLayoutRelease :: proc(bindGroupLayout: BindGroupLayout) ---

	// Methods of Buffer
	BufferDestroy :: proc(buffer: Buffer) ---
	@(link_name="wgpuBufferGetConstMappedRange")
	RawBufferGetConstMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> /* const */ rawptr ---
	BufferGetMapState :: proc(buffer: Buffer) -> BufferMapState ---
	@(link_name="wgpuBufferGetMappedRange")
	RawBufferGetMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> rawptr ---
	BufferGetSize :: proc(buffer: Buffer) -> u64 ---
	BufferGetUsage :: proc(buffer: Buffer) -> BufferUsageFlags ---
	BufferMapAsync :: proc(buffer: Buffer, mode: MapModeFlags, offset: uint, size: uint, callbackInfo: BufferMapCallbackInfo) ---
	BufferSetLabel :: proc(buffer: Buffer, label: StringView) ---
	BufferUnmap :: proc(buffer: Buffer) ---
	BufferAddRef :: proc(buffer: Buffer) ---
	BufferRelease :: proc(buffer: Buffer) ---

	// Methods of CommandBuffer
	CommandBufferSetLabel :: proc(commandBuffer: CommandBuffer, label: StringView) ---
	CommandBufferAddRef :: proc(commandBuffer: CommandBuffer) ---
	CommandBufferRelease :: proc(commandBuffer: CommandBuffer) ---

	// Methods of CommandEncoder
	CommandEncoderBeginComputePass :: proc(commandEncoder: CommandEncoder, /* NULLABLE */ descriptor: /* const */ ^ComputePassDescriptor = nil) -> ComputePassEncoder ---
	CommandEncoderBeginRenderPass :: proc(commandEncoder: CommandEncoder, descriptor: /* const */ ^RenderPassDescriptor) -> RenderPassEncoder ---
	CommandEncoderClearBuffer :: proc(commandEncoder: CommandEncoder, buffer: Buffer, offset: u64, size: u64) ---
	CommandEncoderCopyBufferToBuffer :: proc(commandEncoder: CommandEncoder, source: Buffer, sourceOffset: u64, destination: Buffer, destinationOffset: u64, size: u64) ---
	CommandEncoderCopyBufferToTexture :: proc(commandEncoder: CommandEncoder, source: /* const */ ^TexelCopyBufferInfo, destination: /* const */ ^TexelCopyTextureInfo, copySize: /* const */ ^Extent3D) ---
	CommandEncoderCopyTextureToBuffer :: proc(commandEncoder: CommandEncoder, source: /* const */ ^TexelCopyTextureInfo, destination: /* const */ ^TexelCopyBufferInfo, copySize: /* const */ ^Extent3D) ---
	CommandEncoderCopyTextureToTexture :: proc(commandEncoder: CommandEncoder, source: /* const */ ^TexelCopyTextureInfo, destination: /* const */ ^TexelCopyTextureInfo, copySize: /* const */ ^Extent3D) ---
	CommandEncoderFinish :: proc(commandEncoder: CommandEncoder, /* NULLABLE */ descriptor: /* const */ ^CommandBufferDescriptor = nil) -> CommandBuffer ---
	CommandEncoderInsertDebugMarker :: proc(commandEncoder: CommandEncoder, markerLabel: StringView) ---
	CommandEncoderPopDebugGroup :: proc(commandEncoder: CommandEncoder) ---
	CommandEncoderPushDebugGroup :: proc(commandEncoder: CommandEncoder, groupLabel: StringView) ---
	CommandEncoderResolveQuerySet :: proc(commandEncoder: CommandEncoder, querySet: QuerySet, firstQuery: u32, queryCount: u32, destination: Buffer, destinationOffset: u64) ---
	CommandEncoderSetLabel :: proc(commandEncoder: CommandEncoder, label: StringView) ---
	CommandEncoderWriteTimestamp :: proc(commandEncoder: CommandEncoder, querySet: QuerySet, queryIndex: u32) ---
	CommandEncoderAddRef :: proc(commandEncoder: CommandEncoder) ---
	CommandEncoderRelease :: proc(commandEncoder: CommandEncoder) ---

	// Methods of ComputePassEncoder
	ComputePassEncoderDispatchWorkgroups :: proc(computePassEncoder: ComputePassEncoder, workgroupCountX, workgroupCountY, workgroupCountZ: u32) ---
	ComputePassEncoderDispatchWorkgroupsIndirect :: proc(computePassEncoder: ComputePassEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	ComputePassEncoderEnd :: proc(computePassEncoder: ComputePassEncoder) ---
	ComputePassEncoderInsertDebugMarker :: proc(computePassEncoder: ComputePassEncoder, markerLabel: StringView) ---
	ComputePassEncoderPopDebugGroup :: proc(computePassEncoder: ComputePassEncoder) ---
	ComputePassEncoderPushDebugGroup :: proc(computePassEncoder: ComputePassEncoder, groupLabel: StringView) ---
	@(link_name="wgpuComputePassEncoderSetBindGroup")
	RawComputePassEncoderSetBindGroup :: proc(computePassEncoder: ComputePassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsetCount: uint, dynamicOffsets: /* const */ [^]u32) ---
	ComputePassEncoderSetLabel :: proc(computePassEncoder: ComputePassEncoder, label: StringView) ---
	ComputePassEncoderSetPipeline :: proc(computePassEncoder: ComputePassEncoder, pipeline: ComputePipeline) ---
	ComputePassEncoderAddRef :: proc(computePassEncoder: ComputePassEncoder) ---
	ComputePassEncoderRelease :: proc(computePassEncoder: ComputePassEncoder) ---

	// Methods of ComputePipeline
	ComputePipelineGetBindGroupLayout :: proc(computePipeline: ComputePipeline, groupIndex: u32) -> BindGroupLayout ---
	ComputePipelineSetLabel :: proc(computePipeline: ComputePipeline, label: StringView) ---
	ComputePipelineAddRef :: proc(computePipeline: ComputePipeline) ---
	ComputePipelineRelease :: proc(computePipeline: ComputePipeline) ---

	// Methods of Device
	DeviceCreateBindGroup :: proc(device: Device, descriptor: /* const */ ^BindGroupDescriptor) -> BindGroup ---
	DeviceCreateBindGroupLayout :: proc(device: Device, descriptor: /* const */ ^BindGroupLayoutDescriptor) -> BindGroupLayout ---
	DeviceCreateBuffer :: proc(device: Device, descriptor: /* const */ ^BufferDescriptor) -> Buffer ---
	DeviceCreateCommandEncoder :: proc(device: Device, /* NULLABLE */ descriptor: /* const */ ^CommandEncoderDescriptor = nil) -> CommandEncoder ---
	DeviceCreateComputePipeline :: proc(device: Device, descriptor: /* const */ ^ComputePipelineDescriptor) -> ComputePipeline ---
	DeviceCreateComputePipelineAsync :: proc(device: Device, descriptor: /* const */ ^ComputePipelineDescriptor, callbackInfo: CreateComputePipelineAsyncCallbackInfo) ---
	DeviceCreatePipelineLayout :: proc(device: Device, descriptor: /* const */ ^PipelineLayoutDescriptor) -> PipelineLayout ---
	DeviceCreateQuerySet :: proc(device: Device, descriptor: /* const */ ^QuerySetDescriptor) -> QuerySet ---
	DeviceCreateRenderBundleEncoder :: proc(device: Device, descriptor: /* const */ ^RenderBundleEncoderDescriptor) -> RenderBundleEncoder ---
	DeviceCreateRenderPipeline :: proc(device: Device, descriptor: /* const */ ^RenderPipelineDescriptor) -> RenderPipeline ---
	DeviceCreateRenderPipelineAsync :: proc(device: Device, descriptor: /* const */ ^RenderPipelineDescriptor, callback: CreateRenderPipelineAsyncCallbackInfo) ---
	DeviceCreateSampler :: proc(device: Device, /* NULLABLE */ descriptor: /* const */ ^SamplerDescriptor = nil) -> Sampler ---
	DeviceCreateShaderModule :: proc(device: Device, descriptor: /* const */ ^ShaderModuleDescriptor) -> ShaderModule ---
	DeviceCreateTexture :: proc(device: Device, descriptor: /* const */ ^TextureDescriptor) -> Texture ---
	DeviceDestroy :: proc(device: Device) ---
	DeviceGetAdapterInfo :: proc(device: Device) -> AdapterInfo ---
	@(link_name="wgpuDeviceGetFeatures")
	RawDeviceGetFeatures :: proc(device: Device, features: ^SupportedFeatures) ---
	@(link_name="wgpuDeviceGetLimits")
	RawDeviceGetLimits :: proc(device: Device, limits: ^Limits) -> Status ---
	DeviceGetLostFuture :: proc(device: Device) -> Future ---
	DeviceGetQueue :: proc(device: Device) -> Queue ---
	DeviceHasFeature :: proc(device: Device, feature: FeatureName) -> b32 ---
	DevicePopErrorScope :: proc(device: Device, callbackInfo: PopErrorScopeCallbackInfo) -> Future ---
	DevicePushErrorScope :: proc(device: Device, filter: ErrorFilter) ---
	DeviceSetLabel :: proc(device: Device, label: StringView) ---
	DeviceAddRef :: proc(device: Device) ---
	DeviceRelease :: proc(device: Device) ---

	// Methods of Instance
	InstanceCreateSurface :: proc(instance: Instance, descriptor: /* const */ ^SurfaceDescriptor) -> Surface ---
	@(link_name="wgpuInstanceGetWGSLLanguageFeatures")
	RawInstanceGetWGSLLanguageFeatures :: proc(instance: Instance, features: ^SupportedWGSLLanguageFeatures) -> Status ---
	InstanceHasWGSLLanguageFeature :: proc(instance: Instance, feature: WGSLLanguageFeatureName) -> b32 ---
	InstanceProcessEvents :: proc(instance: Instance) ---
	InstanceRequestAdapter :: proc(instance: Instance, /* NULLABLE */ options: /* const */ ^RequestAdapterOptions, callbackInfo: RequestAdapterCallbackInfo) -> Future ---
	@(link_name="wgpuInstanceWaitAny")
	RawInstanceWaitAny :: proc(instance: Instance, futureCount: uint, /* NULLABLE */ futures: [^]FutureWaitInfo, timeoutNS: u64) -> Status ---
	InstanceAddRef :: proc(instance: Instance) ---
	InstanceRelease :: proc(instance: Instance) ---

	// Methods of PipelineLayout
	PipelineLayoutSetLabel :: proc(pipelineLayout: PipelineLayout, label: StringView) ---
	PipelineLayoutAddRef :: proc(pipelineLayout: PipelineLayout) ---
	PipelineLayoutRelease :: proc(pipelineLayout: PipelineLayout) ---

	// Methods of QuerySet
	QuerySetDestroy :: proc(querySet: QuerySet) ---
	QuerySetGetCount :: proc(querySet: QuerySet) -> u32 ---
	QuerySetGetType :: proc(querySet: QuerySet) -> QueryType ---
	QuerySetSetLabel :: proc(querySet: QuerySet, label: StringView) ---
	QuerySetAddRef :: proc(querySet: QuerySet) ---
	QuerySetRelease :: proc(querySet: QuerySet) ---

	// Methods of Queue
	QueueOnSubmittedWorkDone :: proc(queue: Queue, callbackInfo: QueueWorkDoneCallbackInfo) ---
	QueueSetLabel :: proc(queue: Queue, label: StringView) ---
	@(link_name="wgpuQueueSubmit")
	RawQueueSubmit :: proc(queue: Queue, commandCount: uint, commands: /* const */ [^]CommandBuffer) ---
	QueueWriteBuffer :: proc(queue: Queue, buffer: Buffer, bufferOffset: u64, data: /* const */ rawptr, size: uint) ---
	QueueWriteTexture :: proc(queue: Queue, destination: /* const */ ^TexelCopyTextureInfo, data: /* const */ rawptr, dataSize: uint, dataLayout: /* const */ ^TexelCopyBufferLayout, writeSize: /* const */ ^Extent3D) ---
	QueueAddRef :: proc(queue: Queue) ---
	QueueRelease :: proc(queue: Queue) ---

	// Methods of RenderBundle
	RenderBundleSetLabel :: proc(renderBundle: RenderBundle, label: StringView) ---
	RenderBundleAddRef :: proc(renderBundle: RenderBundle) ---
	RenderBundleRelease :: proc(renderBundle: RenderBundle) ---

	// Methods of RenderBundleEncoder
	RenderBundleEncoderDraw :: proc(renderBundleEncoder: RenderBundleEncoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) ---
	RenderBundleEncoderDrawIndexed :: proc(renderBundleEncoder: RenderBundleEncoder, indexCount: u32, instanceCount: u32, firstIndex: u32, baseVertex: i32, firstInstance: u32) ---
	RenderBundleEncoderDrawIndexedIndirect :: proc(renderBundleEncoder: RenderBundleEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	RenderBundleEncoderDrawIndirect :: proc(renderBundleEncoder: RenderBundleEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	RenderBundleEncoderFinish :: proc(renderBundleEncoder: RenderBundleEncoder, /* NULLABLE */ descriptor: /* const */ ^RenderBundleDescriptor = nil) -> RenderBundle ---
	RenderBundleEncoderInsertDebugMarker :: proc(renderBundleEncoder: RenderBundleEncoder, markerLabel: StringView) ---
	RenderBundleEncoderPopDebugGroup :: proc(renderBundleEncoder: RenderBundleEncoder) ---
	RenderBundleEncoderPushDebugGroup :: proc(renderBundleEncoder: RenderBundleEncoder, groupLabel: StringView) ---
	@(link_name="wgpuRenderBundleEncoderSetBindGroup")
	RawRenderBundleEncoderSetBindGroup :: proc(renderBundleEncoder: RenderBundleEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsetCount: uint, dynamicOffsets: /* const */ [^]u32) ---
	RenderBundleEncoderSetIndexBuffer :: proc(renderBundleEncoder: RenderBundleEncoder, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) ---
	RenderBundleEncoderSetLabel :: proc(renderBundleEncoder: RenderBundleEncoder, label: StringView) ---
	RenderBundleEncoderSetPipeline :: proc(renderBundleEncoder: RenderBundleEncoder, pipeline: RenderPipeline) ---
	RenderBundleEncoderSetVertexBuffer :: proc(renderBundleEncoder: RenderBundleEncoder, slot: u32, /* NULLABLE */ buffer: Buffer, offset: u64, size: u64) ---
	RenderBundleEncoderAddRef :: proc(renderBundleEncoder: RenderBundleEncoder) ---
	RenderBundleEncoderRelease :: proc(renderBundleEncoder: RenderBundleEncoder) ---

	// Methods of RenderPassEncoder
	RenderPassEncoderBeginOcclusionQuery :: proc(renderPassEncoder: RenderPassEncoder, queryIndex: u32) ---
	RenderPassEncoderDraw :: proc(renderPassEncoder: RenderPassEncoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) ---
	RenderPassEncoderDrawIndexed :: proc(renderPassEncoder: RenderPassEncoder, indexCount: u32, instanceCount: u32, firstIndex: u32, baseVertex: i32, firstInstance: u32) ---
	RenderPassEncoderDrawIndexedIndirect :: proc(renderPassEncoder: RenderPassEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	RenderPassEncoderDrawIndirect :: proc(renderPassEncoder: RenderPassEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	RenderPassEncoderEnd :: proc(renderPassEncoder: RenderPassEncoder) ---
	RenderPassEncoderEndOcclusionQuery :: proc(renderPassEncoder: RenderPassEncoder) ---
	@(link_name="wgpuRenderPassEncoderExecuteBundles")
	RawRenderPassEncoderExecuteBundles :: proc(renderPassEncoder: RenderPassEncoder, bundleCount: uint, bundles: /* const */ [^]RenderBundle) ---
	RenderPassEncoderInsertDebugMarker :: proc(renderPassEncoder: RenderPassEncoder, markerLabel: StringView) ---
	RenderPassEncoderPopDebugGroup :: proc(renderPassEncoder: RenderPassEncoder) ---
	RenderPassEncoderPushDebugGroup :: proc(renderPassEncoder: RenderPassEncoder, groupLabel: StringView) ---
	@(link_name="wgpuRenderPassEncoderSetBindGroup")
	RawRenderPassEncoderSetBindGroup :: proc(renderPassEncoder: RenderPassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsetCount: uint, dynamicOffsets: [^]u32) ---
	RenderPassEncoderSetBlendConstant :: proc(renderPassEncoder: RenderPassEncoder, color: /* const */ ^Color) ---
	RenderPassEncoderSetIndexBuffer :: proc(renderPassEncoder: RenderPassEncoder, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) ---
	RenderPassEncoderSetLabel :: proc(renderPassEncoder: RenderPassEncoder, label: StringView) ---
	RenderPassEncoderSetPipeline :: proc(renderPassEncoder: RenderPassEncoder, pipeline: RenderPipeline) ---
	RenderPassEncoderSetScissorRect :: proc(renderPassEncoder: RenderPassEncoder, x, y, width, height: u32) ---
	RenderPassEncoderSetStencilReference :: proc(renderPassEncoder: RenderPassEncoder, reference: u32) ---
	RenderPassEncoderSetVertexBuffer :: proc(renderPassEncoder: RenderPassEncoder, slot: u32, /* NULLABLE */ buffer: Buffer, offset: u64, size: u64) ---
	RenderPassEncoderSetViewport :: proc(renderPassEncoder: RenderPassEncoder, x, y, width, height, minDepth, maxDepth: f32) ---
	RenderPassEncoderAddRef :: proc(renderPassEncoder: RenderPassEncoder) ---
	RenderPassEncoderRelease :: proc(renderPassEncoder: RenderPassEncoder) ---

	// Methods of RenderPipeline
	RenderPipelineGetBindGroupLayout :: proc(renderPipeline: RenderPipeline, groupIndex: u32) -> BindGroupLayout ---
	RenderPipelineSetLabel :: proc(renderPipeline: RenderPipeline, label: StringView) ---
	RenderPipelineAddRef :: proc(renderPipeline: RenderPipeline) ---
	RenderPipelineRelease :: proc(renderPipeline: RenderPipeline) ---

	// Methods of Sampler
	SamplerSetLabel :: proc(sampler: Sampler, label: StringView) ---
	SamplerAddRef :: proc(sampler: Sampler) ---
	SamplerRelease :: proc(sampler: Sampler) ---

	// Methods of ShaderModule
	ShaderModuleGetCompilationInfo :: proc(shaderModule: ShaderModule, callbackInfo: CompilationInfoCallbackInfo) ---
	ShaderModuleSetLabel :: proc(shaderModule: ShaderModule, label: StringView) ---
	ShaderModuleAddRef :: proc(shaderModule: ShaderModule) ---
	ShaderModuleRelease :: proc(shaderModule: ShaderModule) ---

	// Methods of SupportedFeatures
	SupportedFeaturesFreeMembers :: proc(supportedFeatures: SupportedFeatures) ---

	// Methods of SupportedWGSLLanguageFeatures
	SupportedWGSLLanguageFeaturesFreeMembers :: proc(supportedWGSLLanguageFeatures: SupportedWGSLLanguageFeatures) ---

	// Methods of Surface
	SurfaceConfigure :: proc(surface: Surface, config: /* const */ ^SurfaceConfiguration) ---
	@(link_name="wgpuSurfaceGetCapabilities")
	RawSurfaceGetCapabilities :: proc(surface: Surface, adapter: Adapter, capabilities: ^SurfaceCapabilities) -> Status ---
	@(link_name="wgpuSurfaceGetCurrentTexture")
	RawSurfaceGetCurrentTexture :: proc(surface: Surface, surfaceTexture: ^SurfaceTexture) ---
	SurfacePresent :: proc(surface: Surface) -> Status ---
	SurfaceSetLabel :: proc(surface: Surface, label: StringView) ---
	SurfaceUnconfigure :: proc(surface: Surface) ---
	SurfaceAddRef :: proc(surface: Surface) ---
	SurfaceRelease :: proc(surface: Surface) ---

	// Methods of SurfaceCapabilities
	SurfaceCapabilitiesFreeMembers :: proc(surfaceCapabilities: SurfaceCapabilities) ---

	// Methods of Texture
	TextureCreateView :: proc(texture: Texture, /* NULLABLE */ descriptor: /* const */ ^TextureViewDescriptor = nil) -> TextureView ---
	TextureDestroy :: proc(texture: Texture) ---
	TextureGetDepthOrArrayLayers :: proc(texture: Texture) -> u32 ---
	TextureGetDimension :: proc(texture: Texture) -> TextureDimension ---
	TextureGetFormat :: proc(texture: Texture) -> TextureFormat ---
	TextureGetHeight :: proc(texture: Texture) -> u32 ---
	TextureGetMipLevelCount :: proc(texture: Texture) -> u32 ---
	TextureGetSampleCount :: proc(texture: Texture) -> u32 ---
	TextureGetUsage :: proc(texture: Texture) -> TextureUsageFlags ---
	TextureGetWidth :: proc(texture: Texture) -> u32 ---
	TextureSetLabel :: proc(texture: Texture, label: StringView) ---
	TextureAddRef :: proc(texture: Texture) ---
	TextureRelease :: proc(texture: Texture) ---

	// Methods of TextureView
	TextureViewSetLabel :: proc(textureView: TextureView, label: StringView) ---
	TextureViewAddRef :: proc(textureView: TextureView) ---
	TextureViewRelease :: proc(textureView: TextureView) ---
}

// Wrappers of Instance

CreateInstance :: proc "c" (/* NULLABLE */ descriptor: /* const */ ^InstanceDescriptor = nil) -> Instance {
	when ODIN_OS != .JS {
		wgpu_native_version_check()
	}

	return RawCreateInstance(descriptor)
}

GetInstanceCapabilities :: proc "c" () -> (capabilities: InstanceCapabilities, status: Status) {
	status = RawGetInstanceCapabilities(&capabilities)
	return
}

// Wrappers of Adapter

AdapterGetFeatures :: proc "c" (adapter: Adapter) -> (features: SupportedFeatures) {
	RawAdapterGetFeatures(adapter, &features)
	return
}

AdapterGetInfo :: proc "c" (adapter: Adapter) -> (info: AdapterInfo) {
	RawAdapterGetInfo(adapter, &info)
	return
}

AdapterGetLimits :: proc "c" (adapter: Adapter) -> (limits: Limits, status: Status) {
	status = RawAdapterGetLimits(adapter, &limits)
	return
}

// Wrappers of Buffer

/**
 * @param offset
 * Byte offset relative to the beginning of the buffer.
 *
 * @param size
 * Byte size of the range to get. The returned slice is valid for exactly this many bytes.
 *
 * @returns
 * Returns a const slice to beginning of the mapped range.
 * It must not be written; writing to this range causes undefined behavior.
 * Returns `nil` with @ref ImplementationDefinedLogging if:
 *
 * - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
 *   **except** for overlaps with other *const* ranges, which are allowed in C.
 *   (JS does not allow this because const ranges do not exist.)
 */
BufferGetConstMappedRange :: proc "c" (buffer: Buffer, offset: uint, size: uint) -> []byte {
	result := RawBufferGetConstMappedRange(buffer, offset, size)
	return ([^]byte)(result)[:size] if result != nil else nil
}

/**
 * @param offset
 * Byte offset relative to the beginning of the buffer.
 *
 * @param $T
 * Type to interpret the bytes at offset as.
 *
 * @returns
 * Returns a const pointer to beginning of the mapped range as type T.
 * It must not be written; writing to this range causes undefined behavior.
 * Returns `nil` with @ref ImplementationDefinedLogging if:
 *
 * - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
 *   **except** for overlaps with other *const* ranges, which are allowed in C.
 *   (JS does not allow this because const ranges do not exist.)
 */
BufferGetConstMappedRangeTyped :: proc "c" (buffer: Buffer, offset: uint, $T: typeid) -> ^T
	where !intrinsics.type_is_sliceable(T) {

	return (^T)(RawBufferGetConstMappedRange(buffer, offset, size_of(T)))
}

/**
 * @param offset
 * Byte offset relative to the beginning of the buffer.
 *
 * @param length
 * Length of slice of type T to get. The returned slice is valid for exactly this many elements.
 *
 * @param $T
 * Type to interpret the bytes at offset as.
 *
 * @returns
 * Returns a const slice to beginning of the mapped range.
 * It must not be written; writing to this range causes undefined behavior.
 * Returns `nil` with @ref ImplementationDefinedLogging if:
 *
 * - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
 *   **except** for overlaps with other *const* ranges, which are allowed in C.
 *   (JS does not allow this because const ranges do not exist.)
 */
BufferGetConstMappedRangeSlice :: proc "c" (buffer: Buffer, offset: uint, length: uint, $T: typeid) -> []T {
	result := RawBufferGetConstMappedRange(buffer, offset, size_of(T)*length)
	return ([^]T)(result)[:length] if result != nil else nil
}

/**
 * @param offset
 * Byte offset relative to the beginning of the buffer.
 *
 * @param size
 * Byte size of the range to get. The returned slice is valid for exactly this many bytes.
 *
 * @returns
 * Returns a mutable slice to beginning of the mapped range.
 * Returns `nil` with @ref ImplementationDefinedLogging if:
 *
 * - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
 * - The buffer is not mapped with @ref MapMode.Write.
 */
BufferGetMappedRange :: proc "c" (buffer: Buffer, offset: uint, size: uint) -> []byte {
	result := RawBufferGetMappedRange(buffer, offset, size)
	return ([^]byte)(result)[:size] if result != nil else nil
}

/**
 * @param offset
 * Byte offset relative to the beginning of the buffer.
 *
 * @param $T
 * Type to interpret the bytes at offset as.
 *
 * @returns
 * Returns a mutable pointer to beginning of the mapped range as type T.
 * Returns `nil` with @ref ImplementationDefinedLogging if:
 *
 * - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
 * - The buffer is not mapped with @ref MapMode.Write.
 */
BufferGetMappedRangeTyped :: proc "c" (buffer: Buffer, offset: uint, $T: typeid) -> ^T
	where !intrinsics.type_is_sliceable(T) {

	return (^T)(RawBufferGetMappedRange(buffer, offset, size_of(T)))
}

/**
 * @param offset
 * Byte offset relative to the beginning of the buffer.
 *
 * @param length
 * Length of slice of type T to get. The returned slice is valid for exactly this many elements.
 *
 * @param $T
 * Type to interpret the bytes at offset as.
 *
 * @returns
 * Returns a const slice to beginning of the mapped range.
 * It must not be written; writing to this range causes undefined behavior.
 * Returns `nil` with @ref ImplementationDefinedLogging if:
 *
 * - There is any content-timeline error as defined in the WebGPU specification for `getMappedRange()` (alignments, overlaps, etc.)
 * - The buffer is not mapped with @ref MapMode.Write.
 */
BufferGetMappedRangeSlice :: proc "c" (buffer: Buffer, offset: uint, $T: typeid, length: uint) -> []T {
	result := RawBufferGetMappedRange(buffer, offset, size_of(T)*length)
	return ([^]T)(result)[:length] if result != nil else nil
}

// Wrappers of ComputePassEncoder

ComputePassEncoderSetBindGroup :: proc "c" (computePassEncoder: ComputePassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsets: []u32 = nil) {
	RawComputePassEncoderSetBindGroup(computePassEncoder, groupIndex, group, len(dynamicOffsets), raw_data(dynamicOffsets))
}

// Wrappers of Device

DeviceGetFeatures :: proc "c" (device: Device) -> (features: SupportedFeatures) {
	RawDeviceGetFeatures(device, &features)
	return
}

DeviceGetLimits :: proc "c" (device: Device) -> (limits: Limits, status: Status) {
	status = RawDeviceGetLimits(device, &limits)
	return
}

// Wrappers of Instance

InstanceGetWGSLLanguageFeatures :: proc "c" (instance: Instance) -> (features: SupportedWGSLLanguageFeatures, status: Status) {
	status = RawInstanceGetWGSLLanguageFeatures(instance, &features)
	return
}

InstanceWaitAny :: proc "c" (instance: Instance, futures: []FutureWaitInfo, timeoutNS: u64) -> Status {
	return RawInstanceWaitAny(instance, len(futures), raw_data(futures), timeoutNS)
}

BufferWithDataDescriptor :: struct {
	/**
	 * This is a \ref NonNullInputString.
	 */
	label: StringView,
	usage: BufferUsageFlags,
}

DeviceCreateBufferWithDataSlice :: proc "c" (device: Device, descriptor: /* const */ ^BufferWithDataDescriptor, data: []$T) -> (buf: Buffer) {
	size := u64(size_of(T) * len(data))
	buf = DeviceCreateBuffer(device, &{
		label            = descriptor.label,
		usage            = descriptor.usage,
		size             = size,
		mappedAtCreation = true,
	})

	mapping := BufferGetMappedRangeSlice(buf, 0, T, len(data))
	copy(mapping, data)

	BufferUnmap(buf)
	return
}

DeviceCreateBufferWithDataTyped :: proc "c" (device: Device, descriptor: /* const */ ^BufferWithDataDescriptor, data: $T) -> (buf: Buffer)
	where !intrinsics.type_is_sliceable(T) {

	buf = DeviceCreateBuffer(device, &{
		label            = descriptor.label,
		usage            = descriptor.usage,
		size             = size_of(T),
		mappedAtCreation = true,
	})

	mapping := BufferGetMappedRangeTyped(buf, 0, T)
	mapping^ = data

	BufferUnmap(buf)
	return
}

DeviceCreateBufferWithData :: proc {
	DeviceCreateBufferWithDataSlice,
	DeviceCreateBufferWithDataTyped,
}

// Wrappers of Queue

QueueSubmit :: proc "c" (queue: Queue, commands: []CommandBuffer) {
	RawQueueSubmit(queue, len(commands), raw_data(commands))
}

// Wrappers of RenderBundleEncoder

RenderBundleEncoderSetBindGroup :: proc "c" (renderBundleEncoder: RenderBundleEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsets: []u32 = nil) {
	RawRenderBundleEncoderSetBindGroup(renderBundleEncoder, groupIndex, group, len(dynamicOffsets), raw_data(dynamicOffsets))
}

// Wrappers of RenderPassEncoder

RenderPassEncoderExecuteBundles :: proc "c" (renderPassEncoder: RenderPassEncoder, bundles: []RenderBundle) {
	RawRenderPassEncoderExecuteBundles(renderPassEncoder, len(bundles), raw_data(bundles))
}

RenderPassEncoderSetBindGroup :: proc "c" (renderPassEncoder: RenderPassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsets: []u32 = nil) {
	RawRenderPassEncoderSetBindGroup(renderPassEncoder, groupIndex, group, len(dynamicOffsets), raw_data(dynamicOffsets))
}

// Wrappers of Surface

SurfaceGetCapabilities :: proc "c" (surface: Surface, adapter: Adapter) -> (capabilities: SurfaceCapabilities, status: Status) {
	status = RawSurfaceGetCapabilities(surface, adapter, &capabilities)
	return
}

SurfaceGetCurrentTexture :: proc "c" (surface: Surface) -> (surface_texture: SurfaceTexture) {
	RawSurfaceGetCurrentTexture(surface, &surface_texture)
	return
}

// WGPU Native bindings

BINDINGS_VERSION        :: [4]u8{24, 0, 0, 1}
BINDINGS_VERSION_STRING :: "24.0.0.1"

when ODIN_OS != .JS {
	@(private="file")
	wgpu_native_version_check :: proc "c" () {
		v := (transmute([4]u8)GetVersion()).wzyx

		if v != BINDINGS_VERSION {
			buf: [1024]byte
			n := copy(buf[:],  "wgpu-native version mismatch: ")
			n += copy(buf[n:], "bindings are for version ")
			n += copy(buf[n:], BINDINGS_VERSION_STRING)
			n += copy(buf[n:], ", but a different version is linked")
			panic_contextless(string(buf[:n]))
		}
	}

	@(link_prefix="wgpu")
	foreign libwgpu {
		@(link_name="wgpuGenerateReport")
		RawGenerateReport :: proc(instance: Instance, report: ^GlobalReport) ---
		@(link_name="wgpuInstanceEnumerateAdapters")
		RawInstanceEnumerateAdapters :: proc(instance: Instance, /* NULLABLE */ options: /* const */ ^InstanceEnumerateAdapterOptions, adapters: [^]Adapter) -> uint ---

		@(link_name="wgpuQueueSubmitForIndex")
		RawQueueSubmitForIndex :: proc(queue: Queue, commandCount: uint, commands: /* const */ [^]CommandBuffer) -> SubmissionIndex ---

		// Returns true if the queue is empty, or false if there are more queue submissions still in flight.
		DevicePoll :: proc(device: Device, wait: b32, /* NULLABLE */ wrappedSubmissionIndex: /* const */ ^SubmissionIndex = nil) -> b32 ---
		DeviceCreateShaderModuleSpirV :: proc(device: Device, descriptor: /* const */ ^ShaderModuleDescriptorSpirV) -> ShaderModule ---

		SetLogCallback :: proc(callback: LogCallback, userdata: rawptr) ---

		SetLogLevel :: proc(level: LogLevel) ---

		GetVersion :: proc() -> u32 ---

		RenderPassEncoderSetPushConstants :: proc(encoder: RenderPassEncoder, stages: ShaderStageFlags, offset: u32, sizeBytes: u32, data: rawptr) ---
		ComputePassEncoderSetPushConstants :: proc(encoder: ComputePassEncoder, offset: u32, sizeBytes: u32, data: rawptr) ---
		RenderBundleEncoderSetPushConstants :: proc(encoder: RenderBundleEncoder, stages: ShaderStageFlags, offset: u32, sizeBytes: u32, data: rawptr) ---

		RenderPassEncoderMultiDrawIndirect :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count: u32) ---
		RenderPassEncoderMultiDrawIndexedIndirect :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count: u32) ---

		RenderPassEncoderMultiDrawIndirectCount :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count_buffer: Buffer, count_buffer_offset: u64, max_count: u32) ---
		RenderPassEncoderMultiDrawIndexedIndirectCount :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count_buffer: Buffer, count_buffer_offset: u64, max_count: u32) ---

		ComputePassEncoderBeginPipelineStatisticsQuery :: proc(computePassEncoder: ComputePassEncoder, querySet: QuerySet, queryIndex: u32) ---
		ComputePassEncoderEndPipelineStatisticsQuery :: proc(computePassEncoder: ComputePassEncoder) ---
		RenderPassEncoderBeginPipelineStatisticsQuery :: proc(renderPassEncoder: RenderPassEncoder, querySet: QuerySet, queryIndex: u32) ---
		RenderPassEncoderEndPipelineStatisticsQuery :: proc(renderPassEncoder: RenderPassEncoder) ---

		ComputePassEncoderWriteTimestamp :: proc(computePassEncoder: ComputePassEncoder, querySet: QuerySet, queryIndex: u32) ---
		RenderPassEncoderWriteTimestamp :: proc(renderPassEncoder: RenderPassEncoder, querySet: QuerySet, queryIndex: u32) ---
	}

	GenerateReport :: proc "c" (instance: Instance) -> (report: GlobalReport) {
		RawGenerateReport(instance, &report)
		return
	}

	InstanceEnumerateAdapters :: proc(instance: Instance, options: ^InstanceEnumerateAdapterOptions = nil, allocator := context.allocator) -> (adapters: []Adapter) {
		count := RawInstanceEnumerateAdapters(instance, options, nil)
		adapters = make([]Adapter, count, allocator)
		RawInstanceEnumerateAdapters(instance, options, raw_data(adapters))
		return
	}

	QueueSubmitForIndex :: proc "c" (queue: Queue, commands: []CommandBuffer) -> SubmissionIndex {
		return RawQueueSubmitForIndex(queue, len(commands), raw_data(commands))
	}
}
