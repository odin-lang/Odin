package wgpu

import "base:intrinsics"

WGPU_SHARED :: #config(WGPU_SHARED, false)
WGPU_DEBUG  :: #config(WGPU_DEBUG,  false)

@(private) TYPE :: "debug" when WGPU_DEBUG else "release"

when ODIN_OS == .Windows {
	@(private) ARCH :: "x86_64"   when ODIN_ARCH == .amd64 else "x86_64" when ODIN_ARCH == .i386 else #panic("unsupported WGPU Native architecture")
	@(private) EXT  :: ".dll.lib" when WGPU_SHARED else ".lib"
	@(private) LIB  :: "lib/wgpu-windows-" + ARCH + "-" + TYPE + "/wgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v0.19.4.1, make sure to read the README at '" + #directory + "vendor/wgpu/README.md'")
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
	}
} else when ODIN_OS == .Darwin {
	@(private) ARCH :: "x86_64" when ODIN_ARCH == .amd64 else "aarch64" when ODIN_ARCH == .arm64 else #panic("unsupported WGPU Native architecture")
	@(private) EXT  :: ".dylib" when WGPU_SHARED else ".a"
	@(private) LIB  :: "lib/wgpu-macos-" + ARCH + "-" + TYPE + "/libwgpu_native" + EXT

	when !#exists(LIB) {
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v0.19.4.1, make sure to read the README at '" + #directory + "vendor/wgpu/README.md'")
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
		#panic("Could not find the compiled WGPU Native library at '" + #directory + LIB + "', these can be downloaded from https://github.com/gfx-rs/wgpu-native/releases/tag/v0.19.4.1, make sure to read the README at '" + #directory + "vendor/wgpu/README.md'")
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

Flags :: u32

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
	DiscreteGPU = 0x00000000,
	IntegratedGPU = 0x00000001,
	CPU = 0x00000002,
	Unknown = 0x00000003,
}

AddressMode :: enum i32 {
	Repeat = 0x00000000,
	MirrorRepeat = 0x00000001,
	ClampToEdge = 0x00000002,
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
	Zero = 0x00000000,
	One = 0x00000001,
	Src = 0x00000002,
	OneMinusSrc = 0x00000003,
	SrcAlpha = 0x00000004,
	OneMinusSrcAlpha = 0x00000005,
	Dst = 0x00000006,
	OneMinusDst = 0x00000007,
	DstAlpha = 0x00000008,
	OneMinusDstAlpha = 0x00000009,
	SrcAlphaSaturated = 0x0000000A,
	Constant = 0x0000000B,
	OneMinusConstant = 0x0000000C,
}

BlendOperation :: enum i32 {
	Add = 0x00000000,
	Subtract = 0x00000001,
	ReverseSubtract = 0x00000002,
	Min = 0x00000003,
	Max = 0x00000004,
}

BufferBindingType :: enum i32 {
	Undefined = 0x00000000,
	Uniform = 0x00000001,
	Storage = 0x00000002,
	ReadOnlyStorage = 0x00000003,
}

BufferMapAsyncStatus :: enum i32 {
	Success = 0x00000000,
	ValidationError = 0x00000001,
	Unknown = 0x00000002,
	DeviceLost = 0x00000003,
	DestroyedBeforeCallback = 0x00000004,
	UnmappedBeforeCallback = 0x00000005,
	MappingAlreadyPending = 0x00000006,
	OffsetOutOfRange = 0x00000007,
	SizeOutOfRange = 0x00000008,
}

BufferMapState :: enum i32 {
	Unmapped = 0x00000000,
	Pending = 0x00000001,
	Mapped = 0x00000002,
}

CompareFunction :: enum i32 {
	Undefined = 0x00000000,
	Never = 0x00000001,
	Less = 0x00000002,
	LessEqual = 0x00000003,
	Greater = 0x00000004,
	GreaterEqual = 0x00000005,
	Equal = 0x00000006,
	NotEqual = 0x00000007,
	Always = 0x00000008,
}

CompilationInfoRequestStatus :: enum i32 {
	Success = 0x00000000,
	Error = 0x00000001,
	DeviceLost = 0x00000002,
	Unknown = 0x00000003,
}

CompilationMessageType :: enum i32 {
	Error = 0x00000000,
	Warning = 0x00000001,
	Info = 0x00000002,
}

CompositeAlphaMode :: enum i32 {
	Auto = 0x00000000,
	Opaque = 0x00000001,
	Premultiplied = 0x00000002,
	Unpremultiplied = 0x00000003,
	Inherit = 0x00000004,
}

CreatePipelineAsyncStatus :: enum i32 {
	Success = 0x00000000,
	ValidationError = 0x00000001,
	InternalError = 0x00000002,
	DeviceLost = 0x00000003,
	DeviceDestroyed = 0x00000004,
	Unknown = 0x00000005,
}

CullMode :: enum i32 {
	None = 0x00000000,
	Front = 0x00000001,
	Back = 0x00000002,
}

DeviceLostReason :: enum i32 {
	Undefined = 0x00000000,
	Destroyed = 0x00000001,
}

ErrorFilter :: enum i32 {
	Validation = 0x00000000,
	OutOfMemory = 0x00000001,
	Internal = 0x00000002,
}

ErrorType :: enum i32 {
	NoError = 0x00000000,
	Validation = 0x00000001,
	OutOfMemory = 0x00000002,
	Internal = 0x00000003,
	Unknown = 0x00000004,
	DeviceLost = 0x00000005,
}

FeatureName :: enum i32 {
	// WebGPU.
	Undefined = 0x00000000,
	DepthClipControl = 0x00000001,
	Depth32FloatStencil8 = 0x00000002,
	TimestampQuery = 0x00000003,
	TextureCompressionBC = 0x00000004,
	TextureCompressionETC2 = 0x00000005,
	TextureCompressionASTC = 0x00000006,
	IndirectFirstInstance = 0x00000007,
	ShaderF16 = 0x00000008,
	RG11B10UfloatRenderable = 0x00000009,
	BGRA8UnormStorage = 0x0000000A,
	Float32Filterable = 0x0000000B,

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
}

FilterMode :: enum i32 {
	Nearest = 0x00000000,
	Linear = 0x00000001,
}

FrontFace :: enum i32 {
	CCW = 0x00000000,
	CW = 0x00000001,
}

IndexFormat :: enum i32 {
	Undefined = 0x00000000,
	Uint16 = 0x00000001,
	Uint32 = 0x00000002,
}

LoadOp :: enum i32 {
	Undefined = 0x00000000,
	Clear = 0x00000001,
	Load = 0x00000002,
}

MipmapFilterMode :: enum i32 {
	Nearest = 0x00000000,
	Linear = 0x00000001,
}

PowerPreference :: enum i32 {
	Undefined = 0x00000000,
	LowPower = 0x00000001,
	HighPerformance = 0x00000002,
}

PresentMode :: enum i32 {
	Fifo = 0x00000000,
	FifoRelaxed = 0x00000001,
	Immediate = 0x00000002,
	Mailbox = 0x00000003,
}

PrimitiveTopology :: enum i32 {
	PointList = 0x00000000,
	LineList = 0x00000001,
	LineStrip = 0x00000002,
	TriangleList = 0x00000003,
	TriangleStrip = 0x00000004,
}

QueryType :: enum i32 {
	// WebGPU.
	Occlusion = 0x00000000,
	Timestamp = 0x00000001,

	// Native.
	PipelineStatistics = 0x00030000,
}

QueueWorkDoneStatus :: enum i32 {
	Success = 0x00000000,
	Error = 0x00000001,
	Unknown = 0x00000002,
	DeviceLost = 0x00000003,
}

RequestAdapterStatus :: enum i32 {
	Success = 0x00000000,
	Unavailable = 0x00000001,
	Error = 0x00000002,
	Unknown = 0x00000003,
}

RequestDeviceStatus :: enum i32 {
	Success = 0x00000000,
	Error = 0x00000001,
	Unknown = 0x00000002,
}

SType :: enum i32 {
	// WebGPU.
	Invalid = 0x00000000,
	SurfaceDescriptorFromMetalLayer = 0x00000001,
	SurfaceDescriptorFromWindowsHWND = 0x00000002,
	SurfaceDescriptorFromXlibWindow = 0x00000003,
	SurfaceDescriptorFromCanvasHTMLSelector = 0x00000004,
	ShaderModuleSPIRVDescriptor = 0x00000005,
	ShaderModuleWGSLDescriptor = 0x00000006,
	PrimitiveDepthClipControl = 0x00000007,
	SurfaceDescriptorFromWaylandSurface = 0x00000008,
	SurfaceDescriptorFromAndroidNativeWindow = 0x00000009,
	SurfaceDescriptorFromXcbWindow = 0x0000000A,
	RenderPassDescriptorMaxDrawCount = 0x0000000F,

	// Native.
	DeviceExtras = 0x00030001,
	RequiredLimitsExtras,
	PipelineLayoutExtras,
	ShaderModuleGLSLDescriptor,
	SupportedLimitsExtras,
	InstanceExtras,
	BindGroupEntryExtras,
	BindGroupLayoutEntryExtras,
	QuerySetDescriptorExtras,
	SurfaceConfigurationExtras,
}

SamplerBindingType :: enum i32 {
	Undefined = 0x00000000,
	Filtering = 0x00000001,
	NonFiltering = 0x00000002,
	Comparison = 0x00000003,
}

StencilOperation :: enum i32 {
	Keep = 0x00000000,
	Zero = 0x00000001,
	Replace = 0x00000002,
	Invert = 0x00000003,
	IncrementClamp = 0x00000004,
	DecrementClamp = 0x00000005,
	IncrementWrap = 0x00000006,
	DecrementWrap = 0x00000007,
}

StorageTextureAccess :: enum i32 {
	Undefined = 0x00000000,
	WriteOnly = 0x00000001,
	ReadOnly = 0x00000002,
	ReadWrite = 0x00000003,
}

StoreOp :: enum i32 {
	Undefined = 0x00000000,
	Store = 0x00000001,
	Discard = 0x00000002,
}

SurfaceGetCurrentTextureStatus :: enum i32 {
	Success = 0x00000000,
	Timeout = 0x00000001,
	Outdated = 0x00000002,
	Lost = 0x00000003,
	OutOfMemory = 0x00000004,
	DeviceLost = 0x00000005,
}

TextureAspect :: enum i32 {
	All = 0x00000000,
	StencilOnly = 0x00000001,
	DepthOnly = 0x00000002,
}

TextureDimension :: enum i32 {
	_1D = 0x00000000,
	_2D = 0x00000001,
	_3D = 0x00000002,
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
}

TextureSampleType :: enum i32 {
	Undefined = 0x00000000,
	Float = 0x00000001,
	UnfilterableFloat = 0x00000002,
	Depth = 0x00000003,
	Sint = 0x00000004,
	Uint = 0x00000005,
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
	Undefined = 0x00000000,
	Uint8x2 = 0x00000001,
	Uint8x4 = 0x00000002,
	Sint8x2 = 0x00000003,
	Sint8x4 = 0x00000004,
	Unorm8x2 = 0x00000005,
	Unorm8x4 = 0x00000006,
	Snorm8x2 = 0x00000007,
	Snorm8x4 = 0x00000008,
	Uint16x2 = 0x00000009,
	Uint16x4 = 0x0000000A,
	Sint16x2 = 0x0000000B,
	Sint16x4 = 0x0000000C,
	Unorm16x2 = 0x0000000D,
	Unorm16x4 = 0x0000000E,
	Snorm16x2 = 0x0000000F,
	Snorm16x4 = 0x00000010,
	Float16x2 = 0x00000011,
	Float16x4 = 0x00000012,
	Float32 = 0x00000013,
	Float32x2 = 0x00000014,
	Float32x3 = 0x00000015,
	Float32x4 = 0x00000016,
	Uint32 = 0x00000017,
	Uint32x2 = 0x00000018,
	Uint32x3 = 0x00000019,
	Uint32x4 = 0x0000001A,
	Sint32 = 0x0000001B,
	Sint32x2 = 0x0000001C,
	Sint32x3 = 0x0000001D,
	Sint32x4 = 0x0000001E,
}

VertexStepMode :: enum i32 {
	Vertex = 0x00000000,
	Instance = 0x00000001,
	VertexBufferNotUsed = 0x00000002,
}

// WGSLFeatureName :: enum i32 {
//     Undefined = 0x00000000,
//     ReadonlyAndReadwriteStorageTextures = 0x00000001,
//     Packed4x8IntegerDotProduct = 0x00000002,
//     UnrestrictedPointerParameters = 0x00000003,
//     PointerCompositeAccess = 0x00000004,
// }

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


BufferMapAsyncCallback :: #type proc "c" (status: BufferMapAsyncStatus, /* NULLABLE */ userdata: rawptr)
ShaderModuleGetCompilationInfoCallback :: #type proc "c" (status: CompilationInfoRequestStatus, compilationInfo: ^CompilationInfo, /* NULLABLE */ userdata: rawptr)
DeviceCreateComputePipelineAsyncCallback :: #type proc "c" (status: CreatePipelineAsyncStatus, pipeline: ComputePipeline, message: cstring, /* NULLABLE */ userdata: rawptr)
DeviceCreateRenderPipelineAsyncCallback :: #type proc "c" (status: CreatePipelineAsyncStatus, pipeline: RenderPipeline, message: cstring, /* NULLABLE */ userdata: rawptr)

DeviceLostCallback :: #type proc "c" (reason: DeviceLostReason, message: cstring, userdata: rawptr)
ErrorCallback :: #type proc "c" (type: ErrorType, message: cstring, userdata: rawptr)

Proc :: distinct rawptr

QueueOnSubmittedWorkDoneCallback :: #type proc "c" (status: QueueWorkDoneStatus, /* NULLABLE */ userdata: rawptr)
InstanceRequestAdapterCallback :: #type proc "c" (status: RequestAdapterStatus, adapter: Adapter, message: cstring, /* NULLABLE */ userdata: rawptr)
AdapterRequestDeviceCallback :: #type proc "c" (status: RequestDeviceStatus, device: Device, message: cstring, /* NULLABLE */ userdata: rawptr)

// AdapterRequestAdapterInfoCallback :: #type proc "c" (adapterInfo: AdapterInfo, /* NULLABLE */ userdata: rawptr)

ChainedStruct :: struct {
	next:  ^ChainedStruct,
	sType: SType,
}

ChainedStructOut :: struct {
	next:  ^ChainedStructOut,
	sType: SType,
}

// AdapterInfo :: struct {
// 	next: ^ChainedStructOut,
//     vendor: cstring,
//     architecture: cstring,
//     device: cstring,
//     description: cstring,
// 	backendType: BackendType,
// 	adapterType: AdapterType,
// 	vendorID: u32,
// 	deviceID: u32,
// }

AdapterProperties :: struct {
	nextInChain: ^ChainedStructOut,
	vendorID: u32,
	vendorName: cstring,
	architecture: cstring,
	deviceID: u32,
	name: cstring,
	driverDescription: cstring,
	adapterType: AdapterType,
	backendType: BackendType,
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
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	usage: BufferUsageFlags,
	size: u64,
	mappedAtCreation: b32,
}

Color :: struct {
	r: f64,
	g: f64,
	b: f64,
	a: f64,
}

CommandBufferDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
}

CommandEncoderDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
}

CompilationMessage :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ message: cstring,
	type: CompilationMessageType,
	lineNum: u64,
	linePos: u64,
	offset: u64,
	length: u64,
	utf16LinePos: u64,
	utf16Offset: u64,
	utf16Length: u64,
}

ComputePassTimestampWrites :: struct {
	querySet: QuerySet,
	beginningOfPassWriteIndex: u32,
	endOfPassWriteIndex: u32,
}

ConstantEntry :: struct {
	nextInChain: ^ChainedStruct,
	key: cstring,
	value: f64,
}

Extent3D :: struct {
	width: u32,
	height: u32,
	depthOrArrayLayers: u32,
}

InstanceDescriptor :: struct {
	nextInChain: ^ChainedStruct,
}

Limits :: struct {
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
	maxInterStageShaderComponents: u32,
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
	nextInChain: ^ChainedStruct,
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
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	bindGroupLayoutCount: uint,
	bindGroupLayouts: [^]BindGroupLayout `fmt:"v,bindGroupLayoutCount"`,
}

PrimitiveDepthClipControl :: struct {
	using chain: ChainedStruct,
	unclippedDepth: b32,
}

PrimitiveState :: struct {
	nextInChain: ^ChainedStruct,
	topology: PrimitiveTopology,
	stripIndexFormat: IndexFormat,
	frontFace: FrontFace,
	cullMode: CullMode,
}

QuerySetDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	type: QueryType,
	count: u32,
}

QueueDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
}

RenderBundleDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
}

RenderBundleEncoderDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	colorFormatCount: uint,
	colorFormats: [^]TextureFormat `fmt:"v,colorFormatCount"`,
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
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ compatibleSurface: Surface,
	powerPreference: PowerPreference,
	backendType: BackendType,
	forceFallbackAdapter: b32,
}

SamplerBindingLayout :: struct {
	nextInChain: ^ChainedStruct,
	type: SamplerBindingType,
}

SamplerDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
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

ShaderModuleCompilationHint :: struct {
	nextInChain: ^ChainedStruct,
	entryPoint: cstring,
	layout: PipelineLayout,
}

ShaderModuleSPIRVDescriptor :: struct {
	using chain: ChainedStruct,
	codeSize: u32,
	code: /* const */ [^]u32 `fmt:"v,codeSize"`,
}

ShaderModuleWGSLDescriptor :: struct {
	using chain: ChainedStruct,
	code: cstring,
}

StencilFaceState :: struct {
	compare: CompareFunction,
	failOp: StencilOperation,
	depthFailOp: StencilOperation,
	passOp: StencilOperation,
}

StorageTextureBindingLayout :: struct {
	nextInChain: ^ChainedStruct,
	access: StorageTextureAccess,
	format: TextureFormat,
	viewDimension: TextureViewDimension,
}

SurfaceCapabilities :: struct {
	nextInChain: ^ChainedStructOut,
	formatCount: uint,
	formats: /* const */ [^]TextureFormat `fmt:"v,formatCount"`,
	presentModeCount: uint,
	presentModes: /* const */ [^]PresentMode `fmt:"v,presentModeCount"`,
	alphaModeCount: uint,
	alphaModes: /* const */ [^]CompositeAlphaMode `fmt:"v,alphaModeCount"`,
}

SurfaceConfiguration :: struct {
	nextInChain: ^ChainedStruct,
	device: Device,
	format: TextureFormat,
	usage: TextureUsageFlags,
	viewFormatCount: uint,
	viewFormats: [^]TextureFormat `fmt:"v,viewFormatCount"`,
	alphaMode: CompositeAlphaMode,
	width: u32,
	height: u32,
	presentMode: PresentMode,
}

SurfaceDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
}

SurfaceDescriptorFromAndroidNativeWindow :: struct {
	using chain: ChainedStruct,
	window: rawptr,
}

SurfaceDescriptorFromCanvasHTMLSelector :: struct {
	using chain: ChainedStruct,
	selector: cstring,
}

SurfaceDescriptorFromMetalLayer :: struct {
	using chain: ChainedStruct,
	layer: rawptr,
}

SurfaceDescriptorFromWaylandSurface :: struct {
	using chain: ChainedStruct,
	display: rawptr,
	surface: rawptr,
}

SurfaceDescriptorFromWindowsHWND :: struct {
	using chain: ChainedStruct,
	hinstance: rawptr,
	hwnd: rawptr,
}

SurfaceDescriptorFromXcbWindow :: struct {
	using chain: ChainedStruct,
	connection: rawptr,
	window: u32,
}

SurfaceDescriptorFromXlibWindow :: struct {
	using chain: ChainedStruct,
	display: rawptr,
	window: u64,
}

SurfaceTexture :: struct {
	texture: Texture,
	suboptimal: b32,
	status: SurfaceGetCurrentTextureStatus,
}

TextureBindingLayout :: struct {
	nextInChain: ^ChainedStruct,
	sampleType: TextureSampleType,
	viewDimension: TextureViewDimension,
	multisampled: b32,
}

TextureDataLayout :: struct {
	nextInChain: ^ChainedStruct,
	offset: u64,
	bytesPerRow: u32,
	rowsPerImage: u32,
}

TextureViewDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	format: TextureFormat,
	dimension: TextureViewDimension,
	baseMipLevel: u32,
	mipLevelCount: u32,
	baseArrayLayer: u32,
	arrayLayerCount: u32,
	aspect: TextureAspect,
}

VertexAttribute :: struct {
	format: VertexFormat,
	offset: u64,
	shaderLocation: u32,
}

BindGroupDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	layout: BindGroupLayout,
	entryCount: uint,
	entries: [^]BindGroupEntry `fmt:"v,entryCount"`,
}

BindGroupLayoutEntry :: struct {
	nextInChain: ^ChainedStruct,
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
	nextInChain: ^ChainedStruct,
	messageCount: uint,
	messages: [^]CompilationMessage `fmt:"v,messageCount"`,
}

ComputePassDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	/* NULLABLE */ timestampWrites: /* const */ ^ComputePassTimestampWrites,
}

DepthStencilState :: struct {
	nextInChain: ^ChainedStruct,
	format: TextureFormat,
	depthWriteEnabled: b32,
	depthCompare: CompareFunction,
	stencilFront: StencilFaceState,
	stencilBack: StencilFaceState,
	stencilReadMask: u32,
	stencilWriteMask: u32,
	depthBias: i32,
	depthBiasSlopeScale: f32,
	depthBiasClamp: f32,
}

ImageCopyBuffer :: struct {
	nextInChain: ^ChainedStruct,
	layout: TextureDataLayout,
	buffer: Buffer,
}

ImageCopyTexture :: struct {
	nextInChain: ^ChainedStruct,
	texture: Texture,
	mipLevel: u32,
	origin: Origin3D,
	aspect: TextureAspect,
}

ProgrammableStageDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	module: ShaderModule,
	/* NULLABLE */ entryPoint: cstring,
	constantCount: uint,
	constants: [^]ConstantEntry `fmt:"v,constantCount"`,
}

RenderPassColorAttachment :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ view: TextureView,
	// depthSlice: u32,
	/* NULLABLE */ resolveTarget: TextureView,
	loadOp: LoadOp,
	storeOp: StoreOp,
	clearValue: Color,
}

RequiredLimits :: struct {
	nextInChain: ^ChainedStruct,
	limits: Limits,
}

ShaderModuleDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	hintCount: uint,
	hints: [^]ShaderModuleCompilationHint `fmt:"v,hintCount"`,
}

SupportedLimits :: struct {
	nextInChain: ^ChainedStructOut,
	limits: Limits,
}

TextureDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	usage: TextureUsageFlags,
	dimension: TextureDimension,
	size: Extent3D,
	format: TextureFormat,
	mipLevelCount: u32,
	sampleCount: u32,
	viewFormatCount: uint,
	viewFormats: [^]TextureFormat `fmt:"v,viewFormatCount"`,
}

VertexBufferLayout :: struct {
	arrayStride: u64,
	stepMode: VertexStepMode,
	attributeCount: uint,
	attributes: [^]VertexAttribute `fmt:"v,attributeCount"`,
}

BindGroupLayoutDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	entryCount: uint,
	entries: [^]BindGroupLayoutEntry `fmt:"v,entryCount"`,
}

ColorTargetState :: struct {
	nextInChain: ^ChainedStruct,
	format: TextureFormat,
	/* NULLABLE */ blend: /* const */ ^BlendState,
	writeMask: ColorWriteMaskFlags,
}

ComputePipelineDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	/* NULLABLE */ layout: PipelineLayout,
	compute: ProgrammableStageDescriptor,
}

DeviceDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	requiredFeatureCount: uint,
	requiredFeatures: [^]FeatureName `fmt:"v,requiredFeatureCount"`,
	/* NULLABLE */ requiredLimits: /* const */ ^RequiredLimits,
	defaultQueue: QueueDescriptor,
	deviceLostCallback: DeviceLostCallback,
	deviceLostUserdata: rawptr,
}

RenderPassDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	colorAttachmentCount: uint,
	colorAttachments: [^]RenderPassColorAttachment `fmt:"v,colorAttachmentCount"`,
	/* NULLABLE */ depthStencilAttachment: /* const */ ^RenderPassDepthStencilAttachment,
	/* NULLABLE */ occlusionQuerySet: QuerySet,
	/* NULLABLE */ timestampWrites: /* const */ ^RenderPassTimestampWrites,
}

VertexState :: struct {
	nextInChain: ^ChainedStruct,
	module: ShaderModule,
	/* NULLABLE */ entryPoint: cstring,
	constantCount: uint,
	constants: [^]ConstantEntry `fmt:"v,constantCount"`,
	bufferCount: uint,
	buffers: [^]VertexBufferLayout `fmt:"v,bufferCount"`,
}

FragmentState :: struct {
	nextInChain: ^ChainedStruct,
	module: ShaderModule,
	/* NULLABLE */ entryPoint: cstring,
	constantCount: uint,
	constants: [^]ConstantEntry `fmt:"v,constantCount"`,
	targetCount: uint,
	targets: [^]ColorTargetState `fmt:"v,targetCount"`,
}

RenderPipelineDescriptor :: struct {
	nextInChain: ^ChainedStruct,
	/* NULLABLE */ label: cstring,
	/* NULLABLE */ layout: PipelineLayout,
	vertex: VertexState,
	primitive: PrimitiveState,
	/* NULLABLE */ depthStencil: /* const */ ^DepthStencilState,
	multisample: MultisampleState,
	/* NULLABLE */ fragment: /* const */ ^FragmentState,
}

@(link_prefix="wgpu", default_calling_convention="c")
foreign libwgpu {
	CreateInstance :: proc(/* NULLABLE */ descriptor: /* const */ ^InstanceDescriptor = nil) -> Instance ---
	GetProcAddress :: proc(device: Device, procName: cstring) -> Proc ---

	// Methods of Adapter
	@(link_name="wgpuAdapterEnumerateFeatures")
	RawAdapterEnumerateFeatures :: proc(adapter: Adapter, features: [^]FeatureName) -> uint ---
	@(link_name="wgpuAdapterGetLimits")
	RawAdapterGetLimits :: proc(adapter: Adapter, limits: ^SupportedLimits) -> b32 ---
	@(link_name="wgpuAdapterGetProperties")
	RawAdapterGetProperties :: proc(adapter: Adapter, properties: ^AdapterProperties) ---
	AdapterHasFeature :: proc(adapter: Adapter, feature: FeatureName) -> b32 ---
	// AdapterRequestAdapterInfo :: proc(adapter: Adapter, callback: AdapterRequestAdapterInfoCallback, /* NULLABLE */ userdata: rawptr) ---
	AdapterRequestDevice :: proc(adapter: Adapter, /* NULLABLE */ descriptor: /* const */ ^DeviceDescriptor, callback: AdapterRequestDeviceCallback, /* NULLABLE */ userdata: rawptr = nil) ---
	AdapterReference :: proc(adapter: Adapter) ---
	AdapterRelease :: proc(adapter: Adapter) ---

	// Methods of BindGroup
	BindGroupSetLabel :: proc(bindGroup: BindGroup, label: cstring) ---
	BindGroupReference :: proc(bindGroup: BindGroup) ---
	BindGroupRelease :: proc(bindGroup: BindGroup) ---

	// Methods of BindGroupLayout
	BindGroupLayoutSetLabel :: proc(bindGroupLayout: BindGroupLayout, label: cstring) ---
	BindGroupLayoutReference :: proc(bindGroupLayout: BindGroupLayout) ---
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
	BufferMapAsync :: proc(buffer: Buffer, mode: MapModeFlags, offset: uint, size: uint, callback: BufferMapAsyncCallback, /* NULLABLE */ userdata: rawptr = nil) ---
	BufferSetLabel :: proc(buffer: Buffer, label: cstring) ---
	BufferUnmap :: proc(buffer: Buffer) ---
	BufferReference :: proc(buffer: Buffer) ---
	BufferRelease :: proc(buffer: Buffer) ---

	// Methods of CommandBuffer
	CommandBufferSetLabel :: proc(commandBuffer: CommandBuffer, label: cstring) ---
	CommandBufferReference :: proc(commandBuffer: CommandBuffer) ---
	CommandBufferRelease :: proc(commandBuffer: CommandBuffer) ---

	// Methods of CommandEncoder
	CommandEncoderBeginComputePass :: proc(commandEncoder: CommandEncoder, /* NULLABLE */ descriptor: /* const */ ^ComputePassDescriptor = nil) -> ComputePassEncoder ---
	CommandEncoderBeginRenderPass :: proc(commandEncoder: CommandEncoder, descriptor: /* const */ ^RenderPassDescriptor) -> RenderPassEncoder ---
	CommandEncoderClearBuffer :: proc(commandEncoder: CommandEncoder, buffer: Buffer, offset: u64, size: u64) ---
	CommandEncoderCopyBufferToBuffer :: proc(commandEncoder: CommandEncoder, source: Buffer, sourceOffset: u64, destination: Buffer, destinationOffset: u64, size: u64) ---
	CommandEncoderCopyBufferToTexture :: proc(commandEncoder: CommandEncoder, source: /* const */ ^ImageCopyBuffer, destination: /* const */ ^ImageCopyTexture, copySize: /* const */ ^Extent3D) ---
	CommandEncoderCopyTextureToBuffer :: proc(commandEncoder: CommandEncoder, source: /* const */ ^ImageCopyTexture, destination: /* const */ ^ImageCopyBuffer, copySize: /* const */ ^Extent3D) ---
	CommandEncoderCopyTextureToTexture :: proc(commandEncoder: CommandEncoder, source: /* const */ ^ImageCopyTexture, destination: /* const */ ^ImageCopyTexture, copySize: /* const */ ^Extent3D) ---
	CommandEncoderFinish :: proc(commandEncoder: CommandEncoder, /* NULLABLE */ descriptor: /* const */ ^CommandBufferDescriptor = nil) -> CommandBuffer ---
	CommandEncoderInsertDebugMarker :: proc(commandEncoder: CommandEncoder, markerLabel: cstring) ---
	CommandEncoderPopDebugGroup :: proc(commandEncoder: CommandEncoder) ---
	CommandEncoderPushDebugGroup :: proc(commandEncoder: CommandEncoder, groupLabel: cstring) ---
	CommandEncoderResolveQuerySet :: proc(commandEncoder: CommandEncoder, querySet: QuerySet, firstQuery: u32, queryCount: u32, destination: Buffer, destinationOffset: u64) ---
	CommandEncoderSetLabel :: proc(commandEncoder: CommandEncoder, label: cstring) ---
	CommandEncoderWriteTimestamp :: proc(commandEncoder: CommandEncoder, querySet: QuerySet, queryIndex: u32) ---
	CommandEncoderReference :: proc(commandEncoder: CommandEncoder) ---
	CommandEncoderRelease :: proc(commandEncoder: CommandEncoder) ---

	// Methods of ComputePassEncoder
	ComputePassEncoderDispatchWorkgroups :: proc(computePassEncoder: ComputePassEncoder, workgroupCountX: u32, workgroupCountY: u32, workgroupCountZ: u32) ---
	ComputePassEncoderDispatchWorkgroupsIndirect :: proc(computePassEncoder: ComputePassEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	ComputePassEncoderEnd :: proc(computePassEncoder: ComputePassEncoder) ---
	ComputePassEncoderInsertDebugMarker :: proc(computePassEncoder: ComputePassEncoder, markerLabel: cstring) ---
	ComputePassEncoderPopDebugGroup :: proc(computePassEncoder: ComputePassEncoder) ---
	ComputePassEncoderPushDebugGroup :: proc(computePassEncoder: ComputePassEncoder, groupLabel: cstring) ---
	@(link_name="wgpuComputePassEncoderSetBindGroup")
	RawComputePassEncoderSetBindGroup :: proc(computePassEncoder: ComputePassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsetCount: uint, dynamicOffsets: [^]u32) ---
	ComputePassEncoderSetLabel :: proc(computePassEncoder: ComputePassEncoder, label: cstring) ---
	ComputePassEncoderSetPipeline :: proc(computePassEncoder: ComputePassEncoder, pipeline: ComputePipeline) ---
	ComputePassEncoderReference :: proc(computePassEncoder: ComputePassEncoder) ---
	ComputePassEncoderRelease :: proc(computePassEncoder: ComputePassEncoder) ---

	// Methods of ComputePipeline
	ComputePipelineGetBindGroupLayout :: proc(computePipeline: ComputePipeline, groupIndex: u32) -> BindGroupLayout ---
	ComputePipelineSetLabel :: proc(computePipeline: ComputePipeline, label: cstring) ---
	ComputePipelineReference :: proc(computePipeline: ComputePipeline) ---
	ComputePipelineRelease :: proc(computePipeline: ComputePipeline) ---

	// Methods of Device
	DeviceCreateBindGroup :: proc(device: Device, descriptor: /* const */ ^BindGroupDescriptor) -> BindGroup ---
	DeviceCreateBindGroupLayout :: proc(device: Device, descriptor: /* const */ ^BindGroupLayoutDescriptor) -> BindGroupLayout ---
	DeviceCreateBuffer :: proc(device: Device, descriptor: /* const */ ^BufferDescriptor) -> Buffer ---
	DeviceCreateCommandEncoder :: proc(device: Device, /* NULLABLE */ descriptor: /* const */ ^CommandEncoderDescriptor = nil) -> CommandEncoder ---
	DeviceCreateComputePipeline :: proc(device: Device, descriptor: /* const */ ^ComputePipelineDescriptor) -> ComputePipeline ---
	DeviceCreateComputePipelineAsync :: proc(device: Device, descriptor: /* const */ ^ComputePipelineDescriptor, callback: DeviceCreateComputePipelineAsyncCallback, /* NULLABLE */ userdata: rawptr = nil) ---
	DeviceCreatePipelineLayout :: proc(device: Device, descriptor: /* const */ ^PipelineLayoutDescriptor) -> PipelineLayout ---
	DeviceCreateQuerySet :: proc(device: Device, descriptor: /* const */ ^QuerySetDescriptor) -> QuerySet ---
	DeviceCreateRenderBundleEncoder :: proc(device: Device, descriptor: /* const */ ^RenderBundleEncoderDescriptor) -> RenderBundleEncoder ---
	DeviceCreateRenderPipeline :: proc(device: Device, descriptor: /* const */ ^RenderPipelineDescriptor) -> RenderPipeline ---
	DeviceCreateRenderPipelineAsync :: proc(device: Device, descriptor: /* const */ ^RenderPipelineDescriptor, callback: DeviceCreateRenderPipelineAsyncCallback, /* NULLABLE */ userdata: rawptr = nil) ---
	DeviceCreateSampler :: proc(device: Device, /* NULLABLE */ descriptor: /* const */ ^SamplerDescriptor = nil) -> Sampler ---
	DeviceCreateShaderModule :: proc(device: Device, descriptor: /* const */ ^ShaderModuleDescriptor) -> ShaderModule ---
	DeviceCreateTexture :: proc(device: Device, descriptor: /* const */ ^TextureDescriptor) -> Texture ---
	DeviceDestroy :: proc(device: Device) ---
	@(link_name="wgpuDeviceEnumerateFeatures")
	RawDeviceEnumerateFeatures :: proc(device: Device, features: ^FeatureName) -> uint ---
	@(link_name="wgpuDeviceGetLimits")
	RawDeviceGetLimits :: proc(device: Device, limits: ^SupportedLimits) -> b32 ---
	DeviceGetQueue :: proc(device: Device) -> Queue ---
	DeviceHasFeature :: proc(device: Device, feature: FeatureName) -> b32 ---
	DevicePopErrorScope :: proc(device: Device, callback: ErrorCallback, userdata: rawptr) ---
	DevicePushErrorScope :: proc(device: Device, filter: ErrorFilter) ---
	DeviceSetLabel :: proc(device: Device, label: cstring) ---
	DeviceSetUncapturedErrorCallback :: proc(device: Device, callback: ErrorCallback, userdata: rawptr) ---
	DeviceReference :: proc(device: Device) ---
	DeviceRelease :: proc(device: Device) ---

	// Methods of Instance
	InstanceCreateSurface :: proc(instance: Instance, descriptor: /* const */ ^SurfaceDescriptor) -> Surface ---
	// InstanceHasWGSLLanguageFeature :: proc(instance: Instance, feature: WGSLFeatureName) -> b32 ---
	InstanceProcessEvents :: proc(instance: Instance) ---
	InstanceRequestAdapter :: proc(instance: Instance, /* NULLABLE */ options: /* const */ ^RequestAdapterOptions, callback: InstanceRequestAdapterCallback, /* NULLABLE */ userdata: rawptr = nil) ---
	InstanceReference :: proc(instance: Instance) ---
	InstanceRelease :: proc(instance: Instance) ---

	// Methods of PipelineLayout
	PipelineLayoutSetLabel :: proc(pipelineLayout: PipelineLayout, label: cstring) ---
	PipelineLayoutReference :: proc(pipelineLayout: PipelineLayout) ---
	PipelineLayoutRelease :: proc(pipelineLayout: PipelineLayout) ---

	// Methods of QuerySet
	QuerySetDestroy :: proc(querySet: QuerySet) ---
	QuerySetGetCount :: proc(querySet: QuerySet) -> u32 ---
	QuerySetGetType :: proc(querySet: QuerySet) -> QueryType ---
	QuerySetSetLabel :: proc(querySet: QuerySet, label: cstring) ---
	QuerySetReference :: proc(querySet: QuerySet) ---
	QuerySetRelease :: proc(querySet: QuerySet) ---

	// Methods of Queue
	QueueOnSubmittedWorkDone :: proc(queue: Queue, callback: QueueOnSubmittedWorkDoneCallback, /* NULLABLE */ userdata: rawptr = nil) ---
	QueueSetLabel :: proc(queue: Queue, label: cstring) ---
	@(link_name="wgpuQueueSubmit")
	RawQueueSubmit :: proc(queue: Queue, commandCount: uint, commands: [^]CommandBuffer) ---
	QueueWriteBuffer :: proc(queue: Queue, buffer: Buffer, bufferOffset: u64, data: /* const */ rawptr, size: uint) ---
	QueueWriteTexture :: proc(queue: Queue, destination: /* const */ ^ImageCopyTexture, data: /* const */ rawptr, dataSize: uint, dataLayout: /* const */ ^TextureDataLayout, writeSize: /* const */ ^Extent3D) ---
	QueueReference :: proc(queue: Queue) ---
	QueueRelease :: proc(queue: Queue) ---

	// Methods of RenderBundle
	RenderBundleSetLabel :: proc(renderBundle: RenderBundle, label: cstring) ---
	RenderBundleReference :: proc(renderBundle: RenderBundle) ---
	RenderBundleRelease :: proc(renderBundle: RenderBundle) ---

	// Methods of RenderBundleEncoder
	RenderBundleEncoderDraw :: proc(renderBundleEncoder: RenderBundleEncoder, vertexCount: u32, instanceCount: u32, firstVertex: u32, firstInstance: u32) ---
	RenderBundleEncoderDrawIndexed :: proc(renderBundleEncoder: RenderBundleEncoder, indexCount: u32, instanceCount: u32, firstIndex: u32, baseVertex: i32, firstInstance: u32) ---
	RenderBundleEncoderDrawIndexedIndirect :: proc(renderBundleEncoder: RenderBundleEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	RenderBundleEncoderDrawIndirect :: proc(renderBundleEncoder: RenderBundleEncoder, indirectBuffer: Buffer, indirectOffset: u64) ---
	RenderBundleEncoderFinish :: proc(renderBundleEncoder: RenderBundleEncoder, /* NULLABLE */ descriptor: /* const */ ^RenderBundleDescriptor = nil) -> RenderBundle ---
	RenderBundleEncoderInsertDebugMarker :: proc(renderBundleEncoder: RenderBundleEncoder, markerLabel: cstring) ---
	RenderBundleEncoderPopDebugGroup :: proc(renderBundleEncoder: RenderBundleEncoder) ---
	RenderBundleEncoderPushDebugGroup :: proc(renderBundleEncoder: RenderBundleEncoder, groupLabel: cstring) ---
	@(link_name="wgpuRenderBundleEncoderSetBindGroup")
	RawRenderBundleEncoderSetBindGroup :: proc(renderBundleEncoder: RenderBundleEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsetCount: uint, dynamicOffsets: [^]u32) ---
	RenderBundleEncoderSetIndexBuffer :: proc(renderBundleEncoder: RenderBundleEncoder, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) ---
	RenderBundleEncoderSetLabel :: proc(renderBundleEncoder: RenderBundleEncoder, label: cstring) ---
	RenderBundleEncoderSetPipeline :: proc(renderBundleEncoder: RenderBundleEncoder, pipeline: RenderPipeline) ---
	RenderBundleEncoderSetVertexBuffer :: proc(renderBundleEncoder: RenderBundleEncoder, slot: u32, /* NULLABLE */ buffer: Buffer, offset: u64, size: u64) ---
	RenderBundleEncoderReference :: proc(renderBundleEncoder: RenderBundleEncoder) ---
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
	RawRenderPassEncoderExecuteBundles :: proc(renderPassEncoder: RenderPassEncoder, bundleCount: uint, bundles: [^]RenderBundle) ---
	RenderPassEncoderInsertDebugMarker :: proc(renderPassEncoder: RenderPassEncoder, markerLabel: cstring) ---
	RenderPassEncoderPopDebugGroup :: proc(renderPassEncoder: RenderPassEncoder) ---
	RenderPassEncoderPushDebugGroup :: proc(renderPassEncoder: RenderPassEncoder, groupLabel: cstring) ---
	@(link_name="wgpuRenderPassEncoderSetBindGroup")
	RawRenderPassEncoderSetBindGroup :: proc(renderPassEncoder: RenderPassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsetCount: uint, dynamicOffsets: [^]u32) ---
	RenderPassEncoderSetBlendConstant :: proc(renderPassEncoder: RenderPassEncoder, color: /* const */ ^Color) ---
	RenderPassEncoderSetIndexBuffer :: proc(renderPassEncoder: RenderPassEncoder, buffer: Buffer, format: IndexFormat, offset: u64, size: u64) ---
	RenderPassEncoderSetLabel :: proc(renderPassEncoder: RenderPassEncoder, label: cstring) ---
	RenderPassEncoderSetPipeline :: proc(renderPassEncoder: RenderPassEncoder, pipeline: RenderPipeline) ---
	RenderPassEncoderSetScissorRect :: proc(renderPassEncoder: RenderPassEncoder, x: u32, y: u32, width: u32, height: u32) ---
	RenderPassEncoderSetStencilReference :: proc(renderPassEncoder: RenderPassEncoder, reference: u32) ---
	RenderPassEncoderSetVertexBuffer :: proc(renderPassEncoder: RenderPassEncoder, slot: u32, /* NULLABLE */ buffer: Buffer, offset: u64, size: u64) ---
	RenderPassEncoderSetViewport :: proc(renderPassEncoder: RenderPassEncoder, x: f32, y: f32, width: f32, height: f32, minDepth: f32, maxDepth: f32) ---
	RenderPassEncoderReference :: proc(renderPassEncoder: RenderPassEncoder) ---
	RenderPassEncoderRelease :: proc(renderPassEncoder: RenderPassEncoder) ---

	// Methods of RenderPipeline
	RenderPipelineGetBindGroupLayout :: proc(renderPipeline: RenderPipeline, groupIndex: u32) -> BindGroupLayout ---
	RenderPipelineSetLabel :: proc(renderPipeline: RenderPipeline, label: cstring) ---
	RenderPipelineReference :: proc(renderPipeline: RenderPipeline) ---
	RenderPipelineRelease :: proc(renderPipeline: RenderPipeline) ---

	// Methods of Sampler
	SamplerSetLabel :: proc(sampler: Sampler, label: cstring) ---
	SamplerReference :: proc(sampler: Sampler) ---
	SamplerRelease :: proc(sampler: Sampler) ---

	// Methods of ShaderModule
	ShaderModuleGetCompilationInfo :: proc(shaderModule: ShaderModule, callback: ShaderModuleGetCompilationInfoCallback, /* NULLABLE */ userdata: rawptr = nil) ---
	ShaderModuleSetLabel :: proc(shaderModule: ShaderModule, label: cstring) ---
	ShaderModuleReference :: proc(shaderModule: ShaderModule) ---
	ShaderModuleRelease :: proc(shaderModule: ShaderModule) ---

	// Methods of Surface
	SurfaceConfigure :: proc(surface: Surface, config: /* const */ ^SurfaceConfiguration) ---
	@(link_name="wgpuSurfaceGetCapabilities")
	RawSurfaceGetCapabilities :: proc(surface: Surface, adapter: Adapter, capabilities: ^SurfaceCapabilities) ---
	@(link_name="wgpuSurfaceGetCurrentTexture")
	RawSurfaceGetCurrentTexture :: proc(surface: Surface, surfaceTexture: ^SurfaceTexture) ---
	SurfaceGetPreferredFormat :: proc(surface: Surface, adapter: Adapter) -> TextureFormat ---
	SurfacePresent :: proc(surface: Surface) ---
	// SurfaceSetLabel :: proc(surface: Surface, label: cstring) ---
	SurfaceUnconfigure :: proc(surface: Surface) ---
	SurfaceReference :: proc(surface: Surface) ---
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
	TextureSetLabel :: proc(texture: Texture, label: cstring) ---
	TextureReference :: proc(texture: Texture) ---
	TextureRelease :: proc(texture: Texture) ---

	// Methods of TextureView
	TextureViewSetLabel :: proc(textureView: TextureView, label: cstring) ---
	TextureViewReference :: proc(textureView: TextureView) ---
	TextureViewRelease :: proc(textureView: TextureView) ---
}

// Wrappers of Adapter

AdapterEnumerateFeatures :: proc(adapter: Adapter, allocator := context.allocator) -> []FeatureName {
	count := RawAdapterEnumerateFeatures(adapter, nil)
	features := make([]FeatureName, count, allocator)
	RawAdapterEnumerateFeatures(adapter, raw_data(features))
	return features
}

AdapterGetLimits :: proc(adapter: Adapter) -> (limits: SupportedLimits, ok: bool) {
	ok = bool(RawAdapterGetLimits(adapter, &limits))
	return
}

AdapterGetProperties :: proc(adapter: Adapter) -> (properties: AdapterProperties) {
	RawAdapterGetProperties(adapter, &properties)
	return
}

// Wrappers of Buffer

BufferGetConstMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> []byte {
	return ([^]byte)(RawBufferGetConstMappedRange(buffer, offset, size))[:size]
}

BufferGetConstMappedRangeTyped :: proc(buffer: Buffer, offset: uint, $T: typeid) -> ^T
	where !intrinsics.type_is_sliceable(T) {

	return (^T)(RawBufferGetConstMappedRange(buffer, 0, size_of(T)))
}

BufferGetConstMappedRangeSlice :: proc(buffer: Buffer, offset: uint, length: uint, $T: typeid) -> []T {
	return ([^]T)(RawBufferGetConstMappedRange(buffer, offset, size_of(T)*length))[:length]
}

BufferGetMappedRange :: proc(buffer: Buffer, offset: uint, size: uint) -> []byte {
	return ([^]byte)(RawBufferGetMappedRange(buffer, offset, size))[:size]
}

BufferGetMappedRangeTyped :: proc(buffer: Buffer, offset: uint, $T: typeid) -> ^T
	where !intrinsics.type_is_sliceable(T) {

	return (^T)(RawBufferGetMappedRange(buffer, offset, size_of(T)))
}

BufferGetMappedRangeSlice :: proc(buffer: Buffer, offset: uint, $T: typeid, length: uint) -> []T {
	return ([^]T)(RawBufferGetMappedRange(buffer, offset, size_of(T)*length))[:length]
}

// Wrappers of ComputePassEncoder

ComputePassEncoderSetBindGroup :: proc(computePassEncoder: ComputePassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsets: []u32 = nil) {
	RawComputePassEncoderSetBindGroup(computePassEncoder, groupIndex, group, len(dynamicOffsets), raw_data(dynamicOffsets))
}

// Wrappers of Device

DeviceEnumerateFeatures :: proc(device: Device, allocator := context.allocator) -> []FeatureName {
	count := RawDeviceEnumerateFeatures(device, nil)
	features := make([]FeatureName, count, allocator)
	RawDeviceEnumerateFeatures(device, raw_data(features))
	return features
}

DeviceGetLimits :: proc(device: Device) -> (limits: SupportedLimits, ok: bool) {
	ok = bool(RawDeviceGetLimits(device, &limits))
	return
}

BufferWithDataDescriptor :: struct {
	/* NULLABLE */ label: cstring,
	usage: BufferUsageFlags,
}

DeviceCreateBufferWithDataSlice :: proc(device: Device, descriptor: /* const */ ^BufferWithDataDescriptor, data: []$T) -> (buf: Buffer) {
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

DeviceCreateBufferWithDataTyped :: proc(device: Device, descriptor: /* const */ ^BufferWithDataDescriptor, data: $T) -> (buf: Buffer)
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

QueueSubmit :: proc(queue: Queue, commands: []CommandBuffer) {
	RawQueueSubmit(queue, len(commands), raw_data(commands))
}

// Wrappers of RenderBundleEncoder

RenderBundleEncoderSetBindGroup :: proc(renderBundleEncoder: RenderBundleEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsets: []u32 = nil) {
	RawRenderBundleEncoderSetBindGroup(renderBundleEncoder, groupIndex, group, len(dynamicOffsets), raw_data(dynamicOffsets))
}

// Wrappers of RenderPassEncoder

RenderPassEncoderExecuteBundles :: proc(renderPassEncoder: RenderPassEncoder, bundles: []RenderBundle) {
	RawRenderPassEncoderExecuteBundles(renderPassEncoder, len(bundles), raw_data(bundles))
}

RenderPassEncoderSetBindGroup :: proc(renderPassEncoder: RenderPassEncoder, groupIndex: u32, /* NULLABLE */ group: BindGroup, dynamicOffsets: []u32 = nil) {
	RawRenderPassEncoderSetBindGroup(renderPassEncoder, groupIndex, group, len(dynamicOffsets), raw_data(dynamicOffsets))
}

// Wrappers of Surface

SurfaceGetCapabilities :: proc(surface: Surface, adapter: Adapter) -> (capabilities: SurfaceCapabilities) {
	RawSurfaceGetCapabilities(surface, adapter, &capabilities)
	return
}

SurfaceGetCurrentTexture :: proc(surface: Surface) -> (surface_texture: SurfaceTexture) {
	RawSurfaceGetCurrentTexture(surface, &surface_texture)
	return
}

// WGPU Native bindings

BINDINGS_VERSION        :: [4]u8{0, 19, 4, 1}
BINDINGS_VERSION_STRING :: "0.19.4.1"

when ODIN_OS != .JS {
	@(private="file", init)
	wgpu_native_version_check :: proc() {
		v := (transmute([4]u8)GetVersion()).wzyx

		if v != BINDINGS_VERSION {
			buf: [1024]byte
			n := copy(buf[:],  "wgpu-native version mismatch: ")
			n += copy(buf[n:], "bindings are for version ")
			n += copy(buf[n:], BINDINGS_VERSION_STRING)
			n += copy(buf[n:], ", but a different version is linked")
			panic(string(buf[:n]))
		}
	}

	@(link_prefix="wgpu")
	foreign libwgpu {
		@(link_name="wgpuGenerateReport")
		RawGenerateReport :: proc(instance: Instance, report: ^GlobalReport) ---
		@(link_name="wgpuInstanceEnumerateAdapters")
		RawInstanceEnumerateAdapters :: proc(instance: Instance, /* NULLABLE */ options: /* const */ ^InstanceEnumerateAdapterOptions, adapters: [^]Adapter) -> uint ---

		@(link_name="wgpuQueueSubmitForIndex")
		RawQueueSubmitForIndex :: proc(queue: Queue, commandCount: uint, commands: [^]CommandBuffer) -> SubmissionIndex ---

		// Returns true if the queue is empty, or false if there are more queue submissions still in flight.
		DevicePoll :: proc(device: Device, wait: b32, /* NULLABLE */ wrappedSubmissionIndex: /* const */ ^WrappedSubmissionIndex = nil) -> b32 ---

		SetLogCallback :: proc(callback: LogCallback, userdata: rawptr) ---

		SetLogLevel :: proc(level: LogLevel) ---

		GetVersion :: proc() -> u32 ---

		RenderPassEncoderSetPushConstants :: proc(encoder: RenderPassEncoder, stages: ShaderStageFlags, offset: u32, sizeBytes: u32, data: rawptr) ---

		RenderPassEncoderMultiDrawIndirect :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count: u32) ---
		RenderPassEncoderMultiDrawIndexedIndirect :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count: u32) ---

		RenderPassEncoderMultiDrawIndirectCount :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count_buffer: Buffer, count_buffer_offset: u64, max_count: u32) ---
		RenderPassEncoderMultiDrawIndexedIndirectCount :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count_buffer: Buffer, count_buffer_offset: u64, max_count: u32) ---

		ComputePassEncoderBeginPipelineStatisticsQuery :: proc(computePassEncoder: ComputePassEncoder, querySet: QuerySet, queryIndex: u32) ---
		ComputePassEncoderEndPipelineStatisticsQuery :: proc(computePassEncoder: ComputePassEncoder) ---
		RenderPassEncoderBeginPipelineStatisticsQuery :: proc(renderPassEncoder: RenderPassEncoder, querySet: QuerySet, queryIndex: u32) ---
		RenderPassEncoderEndPipelineStatisticsQuery :: proc(renderPassEncoder: RenderPassEncoder) ---
	}

	GenerateReport :: proc(instance: Instance) -> (report: GlobalReport) {
		RawGenerateReport(instance, &report)
		return
	}

	InstanceEnumerateAdapters :: proc(instance: Instance, options: ^InstanceEnumerateAdapterOptions = nil, allocator := context.allocator) -> (adapters: []Adapter) {
		count := RawInstanceEnumerateAdapters(instance, options, nil)
		adapters = make([]Adapter, count, allocator)
		RawInstanceEnumerateAdapters(instance, options, raw_data(adapters))
		return
	}

	QueueSubmitForIndex :: proc(queue: Queue, commands: []CommandBuffer) -> SubmissionIndex {
		return RawQueueSubmitForIndex(queue, len(commands), raw_data(commands))
	}
}
