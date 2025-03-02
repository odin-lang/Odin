package wgpu

import "base:intrinsics"

WGPU_SHARED :: #config(WGPU_SHARED, false)
WGPU_DEBUG  :: #config(WGPU_DEBUG,  false)

@(private) TYPE :: "debug" when WGPU_DEBUG else "release"

when ODIN_OS == .Windows {
	@(private) ARCH :: "x86_64"   when ODIN_ARCH == .amd64 else "x86_64" when ODIN_ARCH == .i386 else #panic("unsupported WGPU Native architecture")
	@(private) EXT  :: ".dll.lib" when WGPU_SHARED else ".lib"
	@(private) LIB  :: "lib/wgpu-windows-" + ARCH + "-msvc-" + TYPE + "/lib/wgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.2, make sure to read the README at '" + #directory + "README.md'")
	}

	@(export)
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
	@(private) LIB  :: "lib/wgpu-macos-" + ARCH + "-" + TYPE + "/lib/libwgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.2, make sure to read the README at '" + #directory + "README.md'")
	}

	@(export)
	foreign import libwgpu {
		LIB,
		"system:CoreFoundation.framework",
		"system:QuartzCore.framework",
		"system:Metal.framework",
	}
} else when ODIN_OS == .Linux {
	@(private) ARCH :: "x86_64" when ODIN_ARCH == .amd64 else "aarch64" when ODIN_ARCH == .arm64 else #panic("unsupported WGPU Native architecture")
	@(private) EXT  :: ".so"    when WGPU_SHARED else ".a"
	@(private) LIB  :: "lib/wgpu-linux-" + ARCH + "-" + TYPE + "/lib/libwgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v24.0.0.2, make sure to read the README at '" + #directory + "README.md'")
	}

	@(export)
	foreign import libwgpu {
		LIB,
		"system:dl",
		"system:m",
	}
} else when ODIN_OS == .JS {
	@(export)
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

StringView :: string

STRLEN :: transmute(int)(max(uint))

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
	Add = 0x00000000,
	Subtract = 0x00000001,
	ReverseSubtract = 0x00000002,
	Min = 0x00000003,
	Max = 0x00000004,
}

BufferBindingType :: enum i32 {
	BindingNotUsed = 0x00000000,
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

CallbackMode :: enum i32 {
	WaitAnyOnly = 0x00000001,
	AllowProcessEvents = 0x00000002,
	AllowSpontaneos = 0x00000003,
}

CompareFunction :: enum i32 {
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

CompositeAlphaMode :: enum i32 {
	Auto = 0x00000000,
	Opaque = 0x00000001,
	Premultiplied = 0x00000002,
	Unpremultiplied = 0x00000003,
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
	Undefined = 0x00000000,
	None = 0x00000001,
	Front = 0x00000002,
	Back = 0x00000003,
}

DeviceLostReason :: enum i32 {
	Undefined = 0x00000000,
	Unknown   = 0x00000001,
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
	Compatibility = 0x00000001,
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
	TextureAdapterSpecificFormatFeatures,
	MultiDrawIndirect,
	MultiDrawIndirectCount,
	VertexWritableStorage,
	TextureBindingArray,
	SampledTextureAndStorageBufferArrayNonUniformIndexing,
	PipelineStatisticsQuery,
	StorageResourceBindingArray,
	PartiallyBoundBindingArray,
	TextureFormat16bitNorm,
	TextureCompressionAstcHdr,
	MappablePrimaryBuffers = 0x0003000E,
	BufferBindingArray,
	UniformBufferAndStorageTextureArrayNonUniformIndexing,
	// TODO: requires wgpu.h api change
	// AddressModeClampToZero,
	// AddressModeClampToBorder,
	// PolygonModeLine,
	// PolygonModePoint,
	// ConservativeRasterization,
	// ClearTexture,
	SpirvShaderPassthrough = 0x00030017,
	// MultiView,
	VertexAttribute64bit = 0x00030019,
	TextureFormatNv12,
	RayTracingAccelarationStructure,
	RayQuery,
	ShaderF64,
	ShaderI16,
	ShaderPrimitiveIndex,
	ShaderEarlyDepthTest,
	Subgroup,
	SubgroupVertex,
	SubgroupBarrier,
	TimestampQueryInsideEncoders,
	TimestampQueryInsidePasses,
}

FilterMode :: enum i32 {
	Undefined = 0x00000000,
	Nearest = 0x00000001,
	Linear = 0x00000002,
}

FrontFace :: enum i32 {
	Undefined = 0x00000000,
	CCW = 0x00000001,
	CW = 0x00000002,
}

IndexFormat :: enum i32 {
	Undefined = 0x00000000,
	Uint16 = 0x00000001,
	Uint32 = 0x00000002,
}

LoadOp :: enum i32 {
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
	Success = 0x00000001,
	InstanceDropped = 0x00000002,
	EmptyStack = 0x00000003,
}

PowerPreference :: enum i32 {
	Undefined = 0x00000000,
	LowPower = 0x00000001,
	HighPerformance = 0x00000002,
}

PresentMode :: enum i32 {
	Undefined = 0x00000000,
	Fifo = 0x00000001,
	FifoRelaxed = 0x00000002,
	Immediate = 0x00000003,
	Mailbox = 0x00000004,
}

PrimitiveTopology :: enum i32 {
	Undefined = 0x00000000,
	PointList = 0x00000001,
	LineList = 0x00000002,
	LineStrip = 0x00000003,
	TriangleList = 0x00000004,
	TriangleStrip = 0x00000005,
}

QueryType :: enum i32 {
	// WebGPU.
	Occlusion = 0x00000001,
	Timestamp = 0x00000002,

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
	NativeLimits,
	PipelineLayoutExtras,
	ShaderModuleGLSLDescriptor,
	SupportedLimitsExtras,
	InstanceExtras,
	BindGroupEntryExtras,
	BindGroupLayoutEntryExtras,
	QuerySetDescriptorExtras,
	SurfaceConfigurationExtras,

	// Odin.
	SurfaceSourceCanvasHTMLSelector = 0x00040001,
}

SamplerBindingType :: enum i32 {
	BindingNotUsed = 0x00000000,
	Undefined = 0x00000001,
	Filtering = 0x00000002,
	NonFiltering = 0x00000003,
	Comparison = 0x00000004,
}

Status :: enum i32 {
	Success = 0x00000001,
	Error = 0x00000002,
}

StencilOperation :: enum i32 {
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
	BindingNotUsed = 0x00000000,
	Undefined = 0x00000001,
	WriteOnly = 0x00000002,
	ReadOnly = 0x00000003,
	ReadWrite = 0x00000004,
}

StoreOp :: enum i32 {
	Undefined = 0x00000000,
	Store = 0x00000001,
	Discard = 0x00000002,
}

SurfaceGetCurrentTextureStatus :: enum i32 {
	SuccessOptimal = 0x00000001,
	SuccessSuboptimal = 0x00000002,
	Timeout = 0x00000003,
	Outdated = 0x00000004,
	Lost = 0x00000005,
	OutOfMemory = 0x00000006,
	DeviceLost = 0x00000007,
	Error = 0x00000008,
}

TextureAspect :: enum i32 {
	Undefined = 0x00000000,
	All = 0x00000001,
	StencilOnly = 0x00000002,
	DepthOnly = 0x00000003,
}

TextureDimension :: enum i32 {
	Undefined = 0x00000000,
	_1D = 0x00000001,
	_2D = 0x00000002,
	_3D = 0x00000003,
}

TextureFormat :: enum i32 {
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
	R16Snorm,
	Rg16Unorm,
	Rg16Snorm,
	Rgba16Unorm,
	Rgba16Snorm,
	// From FeatureName.TextureFormatNv12
	NV12,
}

TextureSampleType :: enum i32 {
	BindingNotUsed = 0x00000000,
	Undefined = 0x00000001,
	Float = 0x00000002,
	UnfilterableFloat = 0x00000003,
	Depth = 0x00000004,
	Sint = 0x00000005,
	Uint = 0x00000006,
}

TextureViewDimension :: enum i32 {
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
	VertexBufferNotUsed = 0x00000000,
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

WaitStatus :: enum i32 {
	Success = 0x00000001,
	TimedOut = 0x00000002,
	UnsupportedTimeout = 0x00000003,
	UnsupportedCount = 0x00000004,
	UnsupportedMixedSource = 0x00000005,
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

ColorWriteMask :: enum i32 {
	Red = 0x00000000,
	Green = 0x00000001,
	Blue = 0x00000002,
	Alpha = 0x00000003,
}
ColorWriteMaskFlags :: bit_set[ColorWriteMask; Flags]
ColorWriteMaskFlags_All :: ColorWriteMaskFlags{ .Red, .Green, .Blue, .Alpha }

MapMode :: enum i32 {
	Read = 0x00000000,
	Write = 0x00000001,
}
MapModeFlags :: bit_set[MapMode; Flags]

ShaderStage :: enum i32 {
	Vertex = 0x00000000,
	Fragment = 0x00000001,
	Compute = 0x00000002,
}
ShaderStageFlags :: bit_set[ShaderStage; Flags]

TextureUsage :: enum i32 {
	CopySrc = 0x00000000,
	CopyDst = 0x00000001,
	TextureBinding = 0x00000002,
	StorageBinding = 0x00000003,
	RenderAttachment = 0x00000004,
}
TextureUsageFlags :: bit_set[TextureUsage; Flags]

Proc :: distinct rawptr

BufferMapCallback :: #type proc "c" (status: MapAsyncStatus, message: StringView, userdata1: rawptr, userdata2: rawptr)
CompilationInfoCallback :: #type proc "c" (status: CompilationInfoRequestStatus, compilationInfo: ^CompilationInfo, userdata1: rawptr, userdata2: rawptr)
CreateComputePipelineAsyncCallback :: #type proc "c" (status: CreatePipelineAsyncStatus, pipeline: ComputePipeline, message: StringView, userdata1: rawptr, userdata2: rawptr)
CreateRenderPipelineAsyncCallback :: #type proc "c" (status: CreatePipelineAsyncStatus, pipeline: RenderPipeline, message: StringView, userdata1: rawptr, userdata2: rawptr)
DeviceLostCallback :: #type proc "c" (device: ^Device, reason: DeviceLostReason, message: StringView, userdata1: rawptr, userdata2: rawptr)
PopErrorScopeCallback :: #type proc "c" (status: PopErrorScopeStatus, type: ErrorType, message: StringView, userdata1: rawptr, userdata2: rawptr)
QueueWorkDoneCallback :: #type proc "c" (status: QueueWorkDoneStatus, userdata1: rawptr, userdata2: rawptr)
RequestAdapterCallback :: #type proc "c" (status: RequestAdapterStatus, adapter: Adapter, message: StringView, userdata1: rawptr, userdata2: rawptr)
RequestDeviceCallback :: #type proc "c" (status: RequestDeviceStatus, adapter: Device, message: StringView, userdata1: rawptr, userdata2: rawptr)
UncapturedErrorCallback :: #type proc "c" (device: ^Device, type: ErrorType, message: StringView, userdata1: rawptr, userdata2: rawptr)

ChainedStruct :: struct {
	next: ^ChainedStruct,
	sType: SType,
}

ChainedStructOut :: struct {
	next: ^ChainedStructOut,
	sType: SType,
}

BufferMapCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: BufferMapCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

CompilationInfoCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: CompilationInfoCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

CreateComputePipelineAsyncCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: CreateComputePipelineAsyncCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

CreateRenderPipelineAsyncCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: CreateRenderPipelineAsyncCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

DeviceLostCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: DeviceLostCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

PopErrorScopeCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: PopErrorScopeCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

QueueWorkDoneCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: QueueWorkDoneCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

RequestAdapterCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: RequestAdapterCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

RequestDeviceCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	mode: CallbackMode,
	callback: RequestDeviceCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

UncapturedErrorCallbackInfo :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	callback: UncapturedErrorCallback,
	userdata1: /* NULLABLE */ rawptr,
	userdata2: /* NULLABLE */ rawptr,
}

AdapterInfo :: struct {
	nextInChain: ^ChainedStructOut,
	vendor: StringView,
	architecture: StringView,
	device: StringView,
	description: StringView,
	backendType: BackendType,
	adapterType: AdapterType,
	vendorID: u32,
	deviceID: u32,
}

BindGroupEntry :: struct {
	nextInChain: ^ChainedStruct,
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
	nextInChain: ^ChainedStruct,
	type: BufferBindingType,
	hasDynamicOffset: b32,
	minBindingSize: u64,
}

BufferDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
	usage: BufferUsageFlags,
	size: u64,
	mappedAtCreation: b32,
}

Color :: [4]f64

CommandBufferDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
}

CommandEncoderDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
}

CompilationMessage :: struct {
	nextInChain: ^ChainedStruct,
	message: StringView,
	type: CompilationMessageType,
	lineNum: u64,
	linePos: u64,
	offset: u64,
	length: u64,
}

ComputePassTimestampWrites :: struct {
	querySet: QuerySet,
	beginningOfPassWriteIndex: u32,
	endOfPassWriteIndex: u32,
}

ConstantEntry :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	key: StringView,
	value: f64,
}

Extent3D :: struct {
	width: u32,
	height: u32,
	depthOrArrayLayers: u32,
}

Future :: struct {
	id: u64,
}

InstanceCapabilities :: struct {
	nextInChain: ^ChainedStructOut,
	timedWaitAnyEnable: b32,
	timedWaitAnyMaxCount: uint,
}

Limits :: struct {
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
	label: StringView,
	bindGroupLayoutCount: uint,
	bindGroupLayouts: [^]BindGroupLayout `fmt:"v,bindGroupLayoutCount"`,
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
	label: StringView,
	type: QueryType,
	count: u32,
}

QueueDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
}

RenderBundleDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
}

RenderBundleEncoderDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
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

RenderPassMaxDrawCount :: struct {
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
	featureLevel: FeatureLevel,
	powerPreference: PowerPreference,
	forceFallbackAdapter: b32,
	backendType: BackendType,
	/* NULLABLE */ compatibleSurface: Surface,
}

SamplerBindingLayout :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	type: SamplerBindingType,
}

SamplerDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
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
	label: StringView,
}

ShaderSourceSPIRV :: struct {
	using chain: ChainedStruct,
	codeSize: u32,
	code: /* const */ [^]u32 `fmt:"v,codeSize"`,
}

ShaderSourceWGSL :: struct {
	using chain: ChainedStruct,
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

SurfaceCapabilities :: struct {
	nextInChain: ^ChainedStructOut,
	usages: TextureUsageFlags,
	formatCount: uint,
	formats: /* const */ [^]TextureFormat `fmt:"v,formatCount"`,
	presentModeCount: uint,
	presentModes: /* const */ [^]PresentMode `fmt:"v,presentModeCount"`,
	alphaModeCount: uint,
	alphaModes: /* const */ [^]CompositeAlphaMode `fmt:"v,alphaModeCount"`,
}

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

SurfaceDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
}

SurfaceSourceAndroidNativeWindow :: struct {
	using chain: ChainedStruct,
	window: rawptr,
}

SurfaceSourceCanvasHTMLSelector :: struct {
	using chain: ChainedStruct,
	selector: StringView,
}

SurfaceSourceMetalLayer :: struct {
	using chain: ChainedStruct,
	layer: rawptr,
}

SurfaceSourceWaylandSurface :: struct {
	using chain: ChainedStruct,
	display: rawptr,
	surface: rawptr,
}

SurfaceSourceWindowsHWND :: struct {
	using chain: ChainedStruct,
	hinstance: rawptr,
	hwnd: rawptr,
}

SurfaceSourceXcbWindow :: struct {
	using chain: ChainedStruct,
	connection: rawptr,
	window: u32,
}

SurfaceSourceXlibWindow :: struct {
	using chain: ChainedStruct,
	display: rawptr,
	window: u64,
}

SurfaceTexture :: struct {
	nextInChain: ^ChainedStructOut,
	texture: Texture,
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
	label: StringView,
	requiredFeatureCount: uint,
	requiredFeatures: /* const */ [^]FeatureName `fmt:"v,requiredFeatureCount"`,
	/* NULLABLE */ requiredLimits: /* const */ ^Limits,
	defaultQueue: QueueDescriptor,
	deviceLostCallbackInfo: DeviceLostCallbackInfo,
	uncapturedErrorCallbackInfo: UncapturedErrorCallbackInfo,
}

FutureWaitInfo :: struct {
	future: Future,
	completed: b32,
}

InstanceDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	features: InstanceCapabilities,
}

ProgrammableStageDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	module: ShaderModule,
	entryPoint: StringView,
	constantCount: uint,
	constants: [^]ConstantEntry `fmt:"v,constantCount"`,
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
	stepMode: VertexStepMode,
	arrayStride: u64,
	attributeCount: uint,
	attributes: /* const */ [^]VertexAttribute `fmt:"v,attributeCount"`,
}

BindGroupLayoutDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
	entryCount: uint,
	entries: /* const */ [^]BindGroupLayoutEntry `fmt:"v,entryCount"`,
}

ColorTargetState :: struct {
	nextInChain: ^ChainedStruct,
	format: TextureFormat,
	/* NULLABLE */ blend: /* const */ ^BlendState,
	writeMask: ColorWriteMaskFlags,
}

ComputePipelineDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	label: StringView,
	/* NULLABLE */ layout: PipelineLayout,
	compute: ProgrammableStageDescriptor,
}

RenderPassDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
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
	entryPoint: StringView,
	constantCount: uint,
	constants: /* const */ [^]ConstantEntry `fmt:"v,constantCount"`,
	bufferCount: uint,
	buffers: /* const */ [^]VertexBufferLayout `fmt:"v,bufferCount"`,
}

FragmentState :: struct {
	nextInChain: /* const */ ^ChainedStruct,
	module: ShaderModule,
	entryPoint: StringView,
	constantCount: uint,
	constants: /* const */ [^]ConstantEntry `fmt:"v,constantCount"`,
	targetCount: uint,
	targets: /* const */ [^]ColorTargetState `fmt:"v,targetCount"`,
}

RenderPipelineDescriptor :: struct {
	nextInChain: /* const */ ^ChainedStruct,
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
	RawAdapterGetInfo :: proc(adapter: Adapter, info: ^AdapterInfo) -> Status ---
	@(link_name="wgpuAdapterGetLimits")
	RawAdapterGetLimits :: proc(adapter: Adapter, limits: ^Limits) -> Status ---
	AdapterHasFeature :: proc(adapter: Adapter, feature: FeatureName) -> b32 ---
	AdapterRequestDevice :: proc(adapter: Adapter, /* NULLABLE */ descriptor: /* const */ ^DeviceDescriptor, callbackInfo: RequestDeviceCallbackInfo) -> Future ---
	AdapterAddRef :: proc(adapter: Adapter) ---
	AdapterRelease :: proc(adapter: Adapter) ---

	// Procs of AdapterInfo
	AdapterInfoFreeMembers :: proc(adapterInfo: AdapterInfo) ---

	// Methods of BindGroup
	BindGroupSetLabel :: proc(bindGroup: BindGroup, label: StringView) ---
	BindGroupAddRef :: proc(bindGroup: BindGroup) ---
	BindGroupRelease :: proc(bindGroup: BindGroup) ---

	// Methods of BindGroupLayout
	BindGroupLayoutSetLabel :: proc(bindGroupLayout: BindGroupLayout, label: cstring) ---
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
	BufferMapAsync :: proc(buffer: Buffer, mode: MapModeFlags, offset: uint, size: uint, callbackInfo: BufferMapCallbackInfo) -> Future ---
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
	ComputePassEncoderDispatchWorkgroups :: proc(computePassEncoder: ComputePassEncoder, workgroupCountX: u32, workgroupCountY: u32, workgroupCountZ: u32) ---
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
	DeviceCreateComputePipelineAsync :: proc(device: Device, descriptor: /* const */ ^ComputePipelineDescriptor, callbackInfo: CreateComputePipelineAsyncCallbackInfo) -> Future ---
	DeviceCreatePipelineLayout :: proc(device: Device, descriptor: /* const */ ^PipelineLayoutDescriptor) -> PipelineLayout ---
	DeviceCreateQuerySet :: proc(device: Device, descriptor: /* const */ ^QuerySetDescriptor) -> QuerySet ---
	DeviceCreateRenderBundleEncoder :: proc(device: Device, descriptor: /* const */ ^RenderBundleEncoderDescriptor) -> RenderBundleEncoder ---
	DeviceCreateRenderPipeline :: proc(device: Device, descriptor: /* const */ ^RenderPipelineDescriptor) -> RenderPipeline ---
	DeviceCreateRenderPipelineAsync :: proc(device: Device, descriptor: /* const */ ^RenderPipelineDescriptor, callbackInfo: CreateRenderPipelineAsyncCallbackInfo) -> Future ---
	DeviceCreateSampler :: proc(device: Device, /* NULLABLE */ descriptor: /* const */ ^SamplerDescriptor = nil) -> Sampler ---
	DeviceCreateShaderModule :: proc(device: Device, descriptor: /* const */ ^ShaderModuleDescriptor) -> ShaderModule ---
	DeviceCreateTexture :: proc(device: Device, descriptor: /* const */ ^TextureDescriptor) -> Texture ---
	DeviceDestroy :: proc(device: Device) ---
	@(link_name="wgpuDeviceGetAdapterInfo")
	RawDeviceGetAdapterInfo :: proc(device: Device, info: ^AdapterInfo) -> Status ---
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
	InstanceWaitAny :: proc(instance: Instance, futureCount: uint, futures: [^]FutureWaitInfo, timeoutNS: u64) -> WaitStatus ---
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
	QueueOnSubmittedWorkDone :: proc(queue: Queue, callbackInfo: QueueWorkDoneCallbackInfo) -> Future ---
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
	RawRenderPassEncoderSetBindGroup :: proc(renderPassEncoder: RenderPassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsetCount: uint, dynamicOffsets: /* const */ [^]u32) ---
	RenderPassEncoderSetBlendConstant :: proc(renderPassEncoder: RenderPassEncoder, color: /* const */ ^Color) ---
	RenderPassEncoderSetIndexBuffer :: proc(renderPassEncoder: RenderPassEncoder, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) ---
	RenderPassEncoderSetLabel :: proc(renderPassEncoder: RenderPassEncoder, label: StringView) ---
	RenderPassEncoderSetPipeline :: proc(renderPassEncoder: RenderPassEncoder, pipeline: RenderPipeline) ---
	RenderPassEncoderSetScissorRect :: proc(renderPassEncoder: RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) ---
	RenderPassEncoderSetStencilReference :: proc(renderPassEncoder: RenderPassEncoder, reference: u32) ---
	RenderPassEncoderSetVertexBuffer :: proc(renderPassEncoder: RenderPassEncoder, slot: u32, /* NULLABLE */ buffer: Buffer, offset: u64, size: u64) ---
	RenderPassEncoderSetViewport :: proc(renderPassEncoder: RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, minDepth: f32, maxDepth: f32) ---
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
	ShaderModuleGetCompilationInfo :: proc(shaderModule: ShaderModule, callbackInfo: CompilationInfoCallbackInfo) -> Future ---
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
		v := (transmute([4]u8)GetVersion()).wzyx

		if v.xyz != BINDINGS_VERSION.xyz {
			buf: [1024]byte
			n := copy(buf[:],  "wgpu-native version mismatch: ")
			n += copy(buf[n:], "bindings are for version ")
			n += copy(buf[n:], BINDINGS_VERSION_STRING)
			n += copy(buf[n:], ", but a different version is linked")
			panic_contextless(string(buf[:n]))
		}
	}

	return RawCreateInstance(descriptor)
}

GetInstanceCapabilities :: proc "c" () -> (capabilities: InstanceCapabilities, status: Status) {
	status = RawGetInstanceCapabilities(&capabilities)
	return
}

InstanceGetWGSLLanguageFeatures :: proc "c" (instance: Instance) -> (features: SupportedWGSLLanguageFeatures, status: Status) {
	status = RawInstanceGetWGSLLanguageFeatures(instance, &features)
	return
}

// Wrappers of Adapter

AdapterGetLimits :: proc "c" (adapter: Adapter) -> (limits: Limits, status: Status) {
	status = RawAdapterGetLimits(adapter, &limits)
	return
}

AdapterGetInfo :: proc "c" (adapter: Adapter) -> (info: AdapterInfo, status: Status) {
	status = RawAdapterGetInfo(adapter, &info)
	return
}

AdapterGetFeatures :: proc "c" (adapter: Adapter) -> (features: SupportedFeatures) {
	RawAdapterGetFeatures(adapter, &features)
	return
}

// Wrappers of Buffer

BufferGetConstMappedRange :: proc "c" (buffer: Buffer, offset: uint, size: uint) -> []byte {
	return ([^]byte)(RawBufferGetConstMappedRange(buffer, offset, size))[:size]
}

BufferGetConstMappedRangeTyped :: proc "c" (buffer: Buffer, offset: uint, $T: typeid) -> ^T
	where !intrinsics.type_is_sliceable(T) {

	return (^T)(RawBufferGetConstMappedRange(buffer, 0, size_of(T)))
}

BufferGetConstMappedRangeSlice :: proc "c" (buffer: Buffer, offset: uint, length: uint, $T: typeid) -> []T {
	return ([^]T)(RawBufferGetConstMappedRange(buffer, offset, size_of(T)*length))[:length]
}

BufferGetMappedRange :: proc "c" (buffer: Buffer, offset: uint, size: uint) -> []byte {
	return ([^]byte)(RawBufferGetMappedRange(buffer, offset, size))[:size]
}

BufferGetMappedRangeTyped :: proc "c" (buffer: Buffer, offset: uint, $T: typeid) -> ^T
	where !intrinsics.type_is_sliceable(T) {

	return (^T)(RawBufferGetMappedRange(buffer, offset, size_of(T)))
}

BufferGetMappedRangeSlice :: proc "c" (buffer: Buffer, offset: uint, $T: typeid, length: uint) -> []T {
	return ([^]T)(RawBufferGetMappedRange(buffer, offset, size_of(T)*length))[:length]
}

// Wrappers of ComputePassEncoder

ComputePassEncoderSetBindGroup :: proc "c" (computePassEncoder: ComputePassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsets: []u32 = nil) {
	RawComputePassEncoderSetBindGroup(computePassEncoder, groupIndex, group, len(dynamicOffsets), raw_data(dynamicOffsets))
}

// Wrappers of Device

DeviceGetLimits :: proc "c" (device: Device) -> (limits: Limits, status: Status) {
	status = RawDeviceGetLimits(device, &limits)
	return
}

DeviceGetAdapterInfo :: proc "c" (device: Device) -> (info: AdapterInfo, status: Status) {
	status = RawDeviceGetAdapterInfo(device, &info)
	return
}

DeviceGetFeatures :: proc "c" (device: Device) -> (features: SupportedFeatures) {
	RawDeviceGetFeatures(device, &features)
	return
}

BufferWithDataDescriptor :: struct {
	/* NULLABLE */ label: StringView,
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
