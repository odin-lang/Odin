package objc_Metal

import NS "core:sys/darwin/Foundation"

AccelerationStructureUsage :: distinct bit_set[AccelerationStructureUsageFlag; NS.UInteger]
AccelerationStructureUsageFlag :: enum NS.UInteger {
	Refit           = 0,
	PreferFastBuild = 1,
	ExtendedLimits  = 2,
}

AccelerationStructureInstanceOptions :: distinct bit_set[AccelerationStructureInstanceOption; u32]
AccelerationStructureInstanceOption :: enum u32 {
	DisableTriangleCulling                     = 0,
	TriangleFrontFacingWindingCounterClockwise = 1,
	Opaque                                     = 2,
	NonOpaque                                  = 3,
}


AccelerationStructureRefitOptions :: distinct bit_set[AccelerationStructureRefitOption; NS.UInteger]
AccelerationStructureRefitOption :: enum NS.UInteger {
	VertexData       = 0,
	PerPrimitiveData = 1,
}


MotionBorderMode :: enum u32 {
	Clamp  = 0,
	Vanish = 1,
}

AccelerationStructureInstanceDescriptorType :: enum NS.UInteger {
	Default = 0,
	UserID  = 1,
	Motion  = 2,
}


DataType :: enum NS.UInteger {
	None                           = 0,
	Struct                         = 1,
	Array                          = 2,
	Float                          = 3,
	Float2                         = 4,
	Float3                         = 5,
	Float4                         = 6,
	Float2x2                       = 7,
	Float2x3                       = 8,
	Float2x4                       = 9,
	Float3x2                       = 10,
	Float3x3                       = 11,
	Float3x4                       = 12,
	Float4x2                       = 13,
	Float4x3                       = 14,
	Float4x4                       = 15,
	Half                           = 16,
	Half2                          = 17,
	Half3                          = 18,
	Half4                          = 19,
	Half2x2                        = 20,
	Half2x3                        = 21,
	Half2x4                        = 22,
	Half3x2                        = 23,
	Half3x3                        = 24,
	Half3x4                        = 25,
	Half4x2                        = 26,
	Half4x3                        = 27,
	Half4x4                        = 28,
	Int                            = 29,
	Int2                           = 30,
	Int3                           = 31,
	Int4                           = 32,
	UInt                           = 33,
	UInt2                          = 34,
	UInt3                          = 35,
	UInt4                          = 36,
	Short                          = 37,
	Short2                         = 38,
	Short3                         = 39,
	Short4                         = 40,
	UShort                         = 41,
	UShort2                        = 42,
	UShort3                        = 43,
	UShort4                        = 44,
	Char                           = 45,
	Char2                          = 46,
	Char3                          = 47,
	Char4                          = 48,
	UChar                          = 49,
	UChar2                         = 50,
	UChar3                         = 51,
	UChar4                         = 52,
	Bool                           = 53,
	Bool2                          = 54,
	Bool3                          = 55,
	Bool4                          = 56,
	Texture                        = 58,
	Sampler                        = 59,
	Pointer                        = 60,
	R8Unorm                        = 62,
	R8Snorm                        = 63,
	R16Unorm                       = 64,
	R16Snorm                       = 65,
	RG8Unorm                       = 66,
	RG8Snorm                       = 67,
	RG16Unorm                      = 68,
	RG16Snorm                      = 69,
	RGBA8Unorm                     = 70,
	RGBA8Unorm_sRGB                = 71,
	RGBA8Snorm                     = 72,
	RGBA16Unorm                    = 73,
	RGBA16Snorm                    = 74,
	RGB10A2Unorm                   = 75,
	RG11B10Float                   = 76,
	RGB9E5Float                    = 77,
	RenderPipeline                 = 78,
	ComputePipeline                = 79,
	IndirectCommandBuffer          = 80,
	Long                           = 81,
	Long2                          = 82,
	Long3                          = 83,
	Long4                          = 84,
	ULong                          = 85,
	ULong2                         = 86,
	ULong3                         = 87,
	ULong4                         = 88,
	VisibleFunctionTable           = 115,
	IntersectionFunctionTable      = 116,
	PrimitiveAccelerationStructure = 117,
	InstanceAccelerationStructure  = 118,
}

ArgumentType :: enum NS.UInteger {
	Buffer                         = 0,
	ThreadgroupMemory              = 1,
	Texture                        = 2,
	Sampler                        = 3,
	ImageblockData                 = 16,
	Imageblock                     = 17,
	VisibleFunctionTable           = 24,
	PrimitiveAccelerationStructure = 25,
	InstanceAccelerationStructure  = 26,
	IntersectionFunctionTable      = 27,
}

ArgumentAccess :: enum NS.UInteger {
	ReadOnly  = 0,
	ReadWrite = 1,
	WriteOnly = 2,
}


BinaryArchiveError :: enum NS.UInteger {
	None               = 0,
	InvalidFile        = 1,
	UnexpectedElement  = 2,
	CompilationFailure = 3,
	InternalError      = 4,
}

BindingType :: enum NS.Integer {
	Buffer                         = 0,
	ThreadgroupMemory              = 1,
	Texture                        = 2,
	Sampler                        = 3,
	ImageblockData                 = 16,
	Imageblock                     = 17,
	VisibleFunctionTable           = 24,
	PrimitiveAccelerationStructure = 25,
	InstanceAccelerationStructure  = 26,
	IntersectionFunctionTable      = 27,
	ObjectPayload                  = 34,
}

BlitOptionFlag :: enum NS.UInteger {
	DepthFromDepthStencil   = 0,
	StencilFromDepthStencil = 1,
	RowLinearPVRTC          = 2,
}
BlitOption :: distinct bit_set[BlitOptionFlag; NS.UInteger]

CaptureError :: enum NS.Integer {
	NotSupported      = 1,
	AlreadyCapturing  = 2,
	InvalidDescriptor = 3,
}

CaptureDestination :: enum NS.Integer {
	DeveloperTools   = 1,
	GPUTraceDocument = 2,
}


CommandBufferStatus :: enum NS.UInteger {
	NotEnqueued = 0,
	Enqueued    = 1,
	Committed   = 2,
	Scheduled   = 3,
	Completed   = 4,
	Error       = 5,
}

CommandBufferError :: enum NS.UInteger {
	None            = 0,
	Internal        = 1,
	Timeout         = 2,
	PageFault       = 3,
	AccessRevoked   = 4,
	Blacklisted     = 4,
	NotPermitted    = 7,
	OutOfMemory     = 8,
	InvalidResource = 9,
	Memoryless      = 10,
	DeviceRemoved   = 11,
	StackOverflow   = 12,
}

CommandBufferErrorOptionFlag :: enum NS.UInteger {
	EncoderExecutionStatus = 0,
}
CommandBufferErrorOption :: distinct bit_set[CommandBufferErrorOptionFlag; NS.UInteger]

CommandEncoderErrorState :: enum NS.Integer {
	Unknown   = 0,
	Completed = 1,
	Affected  = 2,
	Pending   = 3,
	Faulted   = 4,
}

CommandBufferHandler :: distinct rawptr

DispatchType :: enum NS.UInteger {
	Serial     = 0,
	Concurrent = 1,
}

ResourceUsageFlag :: enum NS.UInteger {
	Read   = 0,
	Write  = 1,
	Sample = 2,
}
ResourceUsage :: distinct bit_set[ResourceUsageFlag; NS.UInteger]


BarrierScopeFlag :: enum NS.UInteger {
	Buffers       = 0,
	Textures      = 1,
	RenderTargets = 2,
}
BarrierScope :: distinct bit_set[BarrierScopeFlag; NS.UInteger]



CounterSampleBufferError :: enum NS.Integer {
	OutOfMemory = 0,
	Invalid     = 1,
	Internal    = 2,
}

CompareFunction :: enum NS.UInteger {
	Never        = 0,
	Less         = 1,
	Equal        = 2,
	LessEqual    = 3,
	Greater      = 4,
	NotEqual     = 5,
	GreaterEqual = 6,
	Always       = 7,
}

StencilOperation :: enum NS.UInteger {
	Keep           = 0,
	Zero           = 1,
	Replace        = 2,
	IncrementClamp = 3,
	DecrementClamp = 4,
	Invert         = 5,
	IncrementWrap  = 6,
	DecrementWrap  = 7,
}

FeatureSet :: enum NS.UInteger {
	iOS_GPUFamily1_v1           = 0,
	iOS_GPUFamily2_v1           = 1,
	iOS_GPUFamily1_v2           = 2,
	iOS_GPUFamily2_v2           = 3,
	iOS_GPUFamily3_v1           = 4,
	iOS_GPUFamily1_v3           = 5,
	iOS_GPUFamily2_v3           = 6,
	iOS_GPUFamily3_v2           = 7,
	iOS_GPUFamily1_v4           = 8,
	iOS_GPUFamily2_v4           = 9,
	iOS_GPUFamily3_v3           = 10,
	iOS_GPUFamily4_v1           = 11,
	iOS_GPUFamily1_v5           = 12,
	iOS_GPUFamily2_v5           = 13,
	iOS_GPUFamily3_v4           = 14,
	iOS_GPUFamily4_v2           = 15,
	iOS_GPUFamily5_v1           = 16,
	macOS_GPUFamily1_v1         = 10000,
	OSX_GPUFamily1_v1           = 10000,
	macOS_GPUFamily1_v2         = 10001,
	OSX_GPUFamily1_v2           = 10001,
	OSX_ReadWriteTextureTier2   = 10002,
	macOS_ReadWriteTextureTier2 = 10002,
	macOS_GPUFamily1_v3         = 10003,
	macOS_GPUFamily1_v4         = 10004,
	macOS_GPUFamily2_v1         = 10005,
	watchOS_GPUFamily1_v1       = 20000,
	WatchOS_GPUFamily1_v1       = 20000,
	watchOS_GPUFamily2_v1       = 20001,
	WatchOS_GPUFamily2_v1       = 20001,
	tvOS_GPUFamily1_v1          = 30000,
	TVOS_GPUFamily1_v1          = 30000,
	tvOS_GPUFamily1_v2          = 30001,
	tvOS_GPUFamily1_v3          = 30002,
	tvOS_GPUFamily2_v1          = 30003,
	tvOS_GPUFamily1_v4          = 30004,
	tvOS_GPUFamily2_v2          = 30005,
}

GPUFamily :: enum NS.Integer {
	Apple1       = 1001,
	Apple2       = 1002,
	Apple3       = 1003,
	Apple4       = 1004,
	Apple5       = 1005,
	Apple6       = 1006,
	Apple7       = 1007,
	Apple8       = 1008,
	Mac1         = 2001,
	Mac2         = 2002,
	Common1      = 3001,
	Common2      = 3002,
	Common3      = 3003,
	MacCatalyst1 = 4001,
	MacCatalyst2 = 4002,
	Metal3       = 5001,
}

SparsePageSize :: enum NS.Integer {
	Size16  = 101,
	Size64  = 102,
	Size256 = 103,
}

DeviceLocation :: enum NS.UInteger {
	BuiltIn     = 0,
	Slot        = 1,
	External    = 2,
	Unspecified = NS.UIntegerMax,
}

PipelineOptionFlag :: enum NS.UInteger {
	ArgumentInfo            = 0,
	BufferTypeInfo          = 1,
	FailOnBinaryArchiveMiss = 2,
}
PipelineOption :: distinct bit_set[PipelineOptionFlag; NS.UInteger]

ReadWriteTextureTier :: enum NS.UInteger {
	TierNone = 0,
	Tier1    = 1,
	Tier2    = 2,
}

ArgumentBuffersTier :: enum NS.UInteger {
	Tier1 = 0,
	Tier2 = 1,
}

SparseTextureRegionAlignmentMode :: enum NS.UInteger {
	Outward = 0,
	Inward  = 1,
}

CounterSamplingPoint :: enum NS.UInteger {
	AtStageBoundary        = 0,
	AtDrawBoundary         = 1,
	AtDispatchBoundary     = 2,
	AtTileDispatchBoundary = 3,
	AtBlitBoundary         = 4,
}

DynamicLibraryError :: enum NS.UInteger {
	None                  = 0,
	InvalidFile           = 1,
	CompilationFailure    = 2,
	UnresolvedInstallName = 3,
	DependencyLoadFailure = 4,
	Unsupported           = 5,
}

FunctionOption :: enum NS.UInteger {
	CompileToBinary = 0,
}
FunctionOptions :: distinct bit_set[FunctionOption; NS.UInteger]


FunctionLogType :: enum NS.UInteger {
	Validation = 0,
}

HeapType :: enum NS.Integer {
	Automatic = 0,
	Placement = 1,
	Sparse    = 2,
}

IndirectCommandTypeFlag :: enum NS.UInteger {
	Draw                      = 0,
	DrawIndexed               = 1,
	DrawPatches               = 2,
	DrawIndexedPatches        = 3,
	ConcurrentDispatch        = 5,
	ConcurrentDispatchThreads = 6,
}
IndirectCommandType :: distinct bit_set[IndirectCommandTypeFlag; NS.UInteger]

IntersectionFunctionSignatureFlag :: enum NS.UInteger {
	Instancing      = 0,
	TriangleData    = 1,
	WorldSpaceData  = 2,
	InstanceMotion  = 3,
	PrimitiveMotion = 4,
	ExtendedLimits  = 5,
}
IntersectionFunctionSignature :: distinct bit_set[IntersectionFunctionSignatureFlag; NS.UInteger]

PatchType :: enum NS.UInteger {
	None     = 0,
	Triangle = 1,
	Quad     = 2,
}

FunctionType :: enum NS.UInteger {
	Vertex       = 1,
	Fragment     = 2,
	Kernel       = 3,
	Visible      = 5,
	Intersection = 6,
	Mesh         = 7,
	Object       = 8,

}


LanguageVersion :: enum NS.UInteger {
	Version1_0 = 65536,
	Version1_1 = 65537,
	Version1_2 = 65538,
	Version2_0 = 131072,
	Version2_1 = 131073,
	Version2_2 = 131074,
	Version2_3 = 131075,
	Version2_4 = 131076,
	Version3_0 = 196608,
}

LibraryType :: enum NS.Integer {
	Executable = 0,
	Dynamic    = 1,
}

LibraryOptimizationLevel :: enum NS.Integer {
	Default = 0,
	Size    = 1,
}

LibraryError :: enum NS.UInteger {
	Unsupported      = 1,
	Internal         = 2,
	CompileFailure   = 3,
	CompileWarning   = 4,
	FunctionNotFound = 5,
	FileNotFound     = 6,
}

Mutability :: enum NS.UInteger {
	Default   = 0,
	Mutable   = 1,
	Immutable = 2,
}

PixelFormat :: enum NS.UInteger {
	Invalid               = 0,
	A8Unorm               = 1,
	R8Unorm               = 10,
	R8Unorm_sRGB          = 11,
	R8Snorm               = 12,
	R8Uint                = 13,
	R8Sint                = 14,
	R16Unorm              = 20,
	R16Snorm              = 22,
	R16Uint               = 23,
	R16Sint               = 24,
	R16Float              = 25,
	RG8Unorm              = 30,
	RG8Unorm_sRGB         = 31,
	RG8Snorm              = 32,
	RG8Uint               = 33,
	RG8Sint               = 34,
	B5G6R5Unorm           = 40,
	A1BGR5Unorm           = 41,
	ABGR4Unorm            = 42,
	BGR5A1Unorm           = 43,
	R32Uint               = 53,
	R32Sint               = 54,
	R32Float              = 55,
	RG16Unorm             = 60,
	RG16Snorm             = 62,
	RG16Uint              = 63,
	RG16Sint              = 64,
	RG16Float             = 65,
	RGBA8Unorm            = 70,
	RGBA8Unorm_sRGB       = 71,
	RGBA8Snorm            = 72,
	RGBA8Uint             = 73,
	RGBA8Sint             = 74,
	BGRA8Unorm            = 80,
	BGRA8Unorm_sRGB       = 81,
	RGB10A2Unorm          = 90,
	RGB10A2Uint           = 91,
	RG11B10Float          = 92,
	RGB9E5Float           = 93,
	BGR10A2Unorm          = 94,
	RG32Uint              = 103,
	RG32Sint              = 104,
	RG32Float             = 105,
	RGBA16Unorm           = 110,
	RGBA16Snorm           = 112,
	RGBA16Uint            = 113,
	RGBA16Sint            = 114,
	RGBA16Float           = 115,
	RGBA32Uint            = 123,
	RGBA32Sint            = 124,
	RGBA32Float           = 125,
	BC1_RGBA              = 130,
	BC1_RGBA_sRGB         = 131,
	BC2_RGBA              = 132,
	BC2_RGBA_sRGB         = 133,
	BC3_RGBA              = 134,
	BC3_RGBA_sRGB         = 135,
	BC4_RUnorm            = 140,
	BC4_RSnorm            = 141,
	BC5_RGUnorm           = 142,
	BC5_RGSnorm           = 143,
	BC6H_RGBFloat         = 150,
	BC6H_RGBUfloat        = 151,
	BC7_RGBAUnorm         = 152,
	BC7_RGBAUnorm_sRGB    = 153,
	PVRTC_RGB_2BPP        = 160,
	PVRTC_RGB_2BPP_sRGB   = 161,
	PVRTC_RGB_4BPP        = 162,
	PVRTC_RGB_4BPP_sRGB   = 163,
	PVRTC_RGBA_2BPP       = 164,
	PVRTC_RGBA_2BPP_sRGB  = 165,
	PVRTC_RGBA_4BPP       = 166,
	PVRTC_RGBA_4BPP_sRGB  = 167,
	EAC_R11Unorm          = 170,
	EAC_R11Snorm          = 172,
	EAC_RG11Unorm         = 174,
	EAC_RG11Snorm         = 176,
	EAC_RGBA8             = 178,
	EAC_RGBA8_sRGB        = 179,
	ETC2_RGB8             = 180,
	ETC2_RGB8_sRGB        = 181,
	ETC2_RGB8A1           = 182,
	ETC2_RGB8A1_sRGB      = 183,
	ASTC_4x4_sRGB         = 186,
	ASTC_5x4_sRGB         = 187,
	ASTC_5x5_sRGB         = 188,
	ASTC_6x5_sRGB         = 189,
	ASTC_6x6_sRGB         = 190,
	ASTC_8x5_sRGB         = 192,
	ASTC_8x6_sRGB         = 193,
	ASTC_8x8_sRGB         = 194,
	ASTC_10x5_sRGB        = 195,
	ASTC_10x6_sRGB        = 196,
	ASTC_10x8_sRGB        = 197,
	ASTC_10x10_sRGB       = 198,
	ASTC_12x10_sRGB       = 199,
	ASTC_12x12_sRGB       = 200,
	ASTC_4x4_LDR          = 204,
	ASTC_5x4_LDR          = 205,
	ASTC_5x5_LDR          = 206,
	ASTC_6x5_LDR          = 207,
	ASTC_6x6_LDR          = 208,
	ASTC_8x5_LDR          = 210,
	ASTC_8x6_LDR          = 211,
	ASTC_8x8_LDR          = 212,
	ASTC_10x5_LDR         = 213,
	ASTC_10x6_LDR         = 214,
	ASTC_10x8_LDR         = 215,
	ASTC_10x10_LDR        = 216,
	ASTC_12x10_LDR        = 217,
	ASTC_12x12_LDR        = 218,
	ASTC_4x4_HDR          = 222,
	ASTC_5x4_HDR          = 223,
	ASTC_5x5_HDR          = 224,
	ASTC_6x5_HDR          = 225,
	ASTC_6x6_HDR          = 226,
	ASTC_8x5_HDR          = 228,
	ASTC_8x6_HDR          = 229,
	ASTC_8x8_HDR          = 230,
	ASTC_10x5_HDR         = 231,
	ASTC_10x6_HDR         = 232,
	ASTC_10x8_HDR         = 233,
	ASTC_10x10_HDR        = 234,
	ASTC_12x10_HDR        = 235,
	ASTC_12x12_HDR        = 236,
	GBGR422               = 240,
	BGRG422               = 241,
	Depth16Unorm          = 250,
	Depth32Float          = 252,
	Stencil8              = 253,
	Depth24Unorm_Stencil8 = 255,
	Depth32Float_Stencil8 = 260,
	X32_Stencil8          = 261,
	X24_Stencil8          = 262,
	BGRA10_XR             = 552,
	BGRA10_XR_sRGB        = 553,
	BGR10_XR              = 554,
	BGR10_XR_sRGB         = 555,
}


PrimitiveType :: enum NS.UInteger {
	Point         = 0,
	Line          = 1,
	LineStrip     = 2,
	Triangle      = 3,
	TriangleStrip = 4,
}

VisibilityResultMode :: enum NS.UInteger {
	Disabled = 0,
	Boolean  = 1,
	Counting = 2,
}

CullMode :: enum NS.UInteger {
	None  = 0,
	Front = 1,
	Back  = 2,
}

Winding :: enum NS.UInteger {
	Clockwise        = 0,
	CounterClockwise = 1,
}

DepthClipMode :: enum NS.UInteger {
	Clip  = 0,
	Clamp = 1,
}

TriangleFillMode :: enum NS.UInteger {
	Fill  = 0,
	Lines = 1,
}

RenderStage :: enum NS.UInteger {
	Vertex   = 0,
	Fragment = 1,
	Tile     = 2,
	Object   = 3,
	Mesh     = 4,
}
RenderStages :: distinct bit_set[RenderStage; NS.UInteger]


LoadAction :: enum NS.UInteger {
	DontCare = 0,
	Load = 1,
	Clear = 2,
}

StoreAction :: enum NS.UInteger {
	DontCare                   = 0,
	Store                      = 1,
	MultisampleResolve         = 2,
	StoreAndMultisampleResolve = 3,
	Unknown                    = 4,
	CustomSampleDepthStore     = 5,
}

StoreActionOption :: enum NS.UInteger {
	CustomSamplePositions = 1,
}
StoreActionOptions :: distinct bit_set[StoreActionOption; NS.UInteger]

MultisampleDepthResolveFilter :: enum NS.UInteger {
	Sample0 = 0,
	Min     = 1,
	Max     = 2,
}

MultisampleStencilResolveFilter :: enum NS.UInteger {
	Sample0             = 0,
	DepthResolvedSample = 1,
}

BlendFactor :: enum NS.UInteger {
	Zero                     = 0,
	One                      = 1,
	SourceColor              = 2,
	OneMinusSourceColor      = 3,
	SourceAlpha              = 4,
	OneMinusSourceAlpha      = 5,
	DestinationColor         = 6,
	OneMinusDestinationColor = 7,
	DestinationAlpha         = 8,
	OneMinusDestinationAlpha = 9,
	SourceAlphaSaturated     = 10,
	BlendColor               = 11,
	OneMinusBlendColor       = 12,
	BlendAlpha               = 13,
	OneMinusBlendAlpha       = 14,
	Source1Color             = 15,
	OneMinusSource1Color     = 16,
	Source1Alpha             = 17,
	OneMinusSource1Alpha     = 18,
}

BlendOperation :: enum NS.UInteger {
	Add             = 0,
	Subtract        = 1,
	ReverseSubtract = 2,
	Min             = 3,
	Max             = 4,
}

ColorWriteMaskFlag :: enum NS.UInteger {
	Alpha = 0,
	Blue  = 1,
	Green = 2,
	Red   = 3,
}
ColorWriteMask :: distinct bit_set[ColorWriteMaskFlag; NS.UInteger]
ColorWriteMaskAll :: ColorWriteMask{.Alpha, .Blue, .Green, .Red}

PrimitiveTopologyClass :: enum NS.UInteger {
	Unspecified = 0,
	Point       = 1,
	Line        = 2,
	Triangle    = 3,
}

TessellationPartitionMode :: enum NS.UInteger {
	Pow2           = 0,
	Integer        = 1,
	FractionalOdd  = 2,
	FractionalEven = 3,
}

TessellationFactorStepFunction :: enum NS.UInteger {
	Constant               = 0,
	PerPatch               = 1,
	PerInstance            = 2,
	PerPatchAndPerInstance = 3,
}

TessellationFactorFormat :: enum NS.UInteger {
	Half = 0,
}

TessellationControlPointIndexType :: enum NS.UInteger {
	None   = 0,
	UInt16 = 1,
	UInt32 = 2,
}

PurgeableState :: enum NS.UInteger {
	KeepCurrent = 1,
	NonVolatile = 2,
	Volatile    = 3,
	Empty       = 4,
}

CPUCacheMode :: enum NS.UInteger {
	DefaultCache  = 0,
	WriteCombined = 1,
}

StorageMode :: enum NS.UInteger {
	Shared     = 0,
	Managed    = 1,
	Private    = 2,
	Memoryless = 3,
}

HazardTrackingMode :: enum NS.UInteger {
	Default   = 0,
	Untracked = 1,
	Tracked   = 2,
}

ResourceOption :: enum NS.UInteger {
	CPUCacheModeWriteCombined   = 0,
	StorageModeManaged          = 4,
	StorageModePrivate          = 5,
	HazardTrackingModeUntracked = 8,
	HazardTrackingModeTracked   = 9,
}
ResourceOptions :: distinct bit_set[ResourceOption; NS.UInteger]

ResourceStorageModeShared         :: ResourceOptions{}
ResourceHazardTrackingModeDefault :: ResourceOptions{}
ResourceCPUCacheModeDefaultCache  :: ResourceOptions{}
ResourceOptionCPUCacheModeDefault :: ResourceOptions{}
ResourceStorageModeMemoryless     :: ResourceOptions{.StorageModeManaged, .StorageModePrivate}

SparseTextureMappingMode :: enum NS.UInteger {
	Map   = 0,
	Unmap = 1,
}

SamplerMinMagFilter :: enum NS.UInteger {
	Nearest = 0,
	Linear  = 1,
}

SamplerMipFilter :: enum NS.UInteger {
	NotMipmapped = 0,
	Nearest      = 1,
	Linear       = 2,
}

SamplerAddressMode :: enum NS.UInteger {
	ClampToEdge        = 0,
	MirrorClampToEdge  = 1,
	Repeat             = 2,
	MirrorRepeat       = 3,
	ClampToZero        = 4,
	ClampToBorderColor = 5,
}

SamplerBorderColor :: enum NS.UInteger {
	TransparentBlack = 0,
	OpaqueBlack      = 1,
	OpaqueWhite      = 2,
}


AttributeFormat :: enum NS.UInteger {
	Invalid               = 0,
	UChar2                = 1,
	UChar3                = 2,
	UChar4                = 3,
	Char2                 = 4,
	Char3                 = 5,
	Char4                 = 6,
	UChar2Normalized      = 7,
	UChar3Normalized      = 8,
	UChar4Normalized      = 9,
	Char2Normalized       = 10,
	Char3Normalized       = 11,
	Char4Normalized       = 12,
	UShort2               = 13,
	UShort3               = 14,
	UShort4               = 15,
	Short2                = 16,
	Short3                = 17,
	Short4                = 18,
	UShort2Normalized     = 19,
	UShort3Normalized     = 20,
	UShort4Normalized     = 21,
	Short2Normalized      = 22,
	Short3Normalized      = 23,
	Short4Normalized      = 24,
	Half2                 = 25,
	Half3                 = 26,
	Half4                 = 27,
	Float                 = 28,
	Float2                = 29,
	Float3                = 30,
	Float4                = 31,
	Int                   = 32,
	Int2                  = 33,
	Int3                  = 34,
	Int4                  = 35,
	UInt                  = 36,
	UInt2                 = 37,
	UInt3                 = 38,
	UInt4                 = 39,
	Int1010102Normalized  = 40,
	UInt1010102Normalized = 41,
	UChar4Normalized_BGRA = 42,
	UChar                 = 45,
	Char                  = 46,
	UCharNormalized       = 47,
	CharNormalized        = 48,
	UShort                = 49,
	Short                 = 50,
	UShortNormalized      = 51,
	ShortNormalized       = 52,
	Half                  = 53,
}

IndexType :: enum NS.UInteger {
	UInt16 = 0,
	UInt32 = 1,
}

IOPriority :: enum NS.Integer {
	High   = 0,
	Normal = 1,
	Low    = 2,
}

IOCommandQueueType :: enum NS.Integer {
	Concurrent = 0,
	Serial     = 1,
}

IOError :: enum NS.Integer {
	URLInvalid = 1,
	Internal   = 2,
}

IOStatus :: enum NS.Integer {
	Pending   = 0,
	Cancelled = 1,
	Error     = 2,
	Complete  = 3,
}

IOCompressionMethod :: enum NS.Integer {
	Zlib     = 0,
	LZFSE    = 1,
	LZ4      = 2,
	LZMA     = 3,
	LZBitmap = 4,
}

IOCompressionStatus :: enum NS.Integer {
	Complete = 0,
	Error    = 1,
}

StepFunction :: enum NS.UInteger {
	Constant                     = 0,
	PerVertex                    = 1,
	PerInstance                  = 2,
	PerPatch                     = 3,
	PerPatchControlPoint         = 4,
	ThreadPositionInGridX        = 5,
	ThreadPositionInGridY        = 6,
	ThreadPositionInGridXIndexed = 7,
	ThreadPositionInGridYIndexed = 8,
}

TextureType :: enum NS.UInteger {
	Type1D                 = 0,
	Type1DArray            = 1,
	Type2D                 = 2,
	Type2DArray            = 3,
	Type2DMultisample      = 4,
	TypeCube               = 5,
	TypeCubeArray          = 6,
	Type3D                 = 7,
	Type2DMultisampleArray = 8,
	TypeTextureBuffer      = 9,
}

TextureSwizzle :: enum u8 {
	Zero  = 0,
	One   = 1,
	Red   = 2,
	Green = 3,
	Blue  = 4,
	Alpha = 5,
}

TextureUsageFlag :: enum NS.UInteger {
	ShaderRead      = 0,
	ShaderWrite     = 1,
	RenderTarget    = 2,
	PixelFormatView = 4,
}
TextureUsage :: distinct bit_set[TextureUsageFlag; NS.UInteger]

TextureCompressionType :: enum NS.Integer {
	Lossless = 0,
	Lossy    = 1,
}

VertexFormat :: enum NS.UInteger {
	Invalid               = 0,
	UChar2                = 1,
	UChar3                = 2,
	UChar4                = 3,
	Char2                 = 4,
	Char3                 = 5,
	Char4                 = 6,
	UChar2Normalized      = 7,
	UChar3Normalized      = 8,
	UChar4Normalized      = 9,
	Char2Normalized       = 10,
	Char3Normalized       = 11,
	Char4Normalized       = 12,
	UShort2               = 13,
	UShort3               = 14,
	UShort4               = 15,
	Short2                = 16,
	Short3                = 17,
	Short4                = 18,
	UShort2Normalized     = 19,
	UShort3Normalized     = 20,
	UShort4Normalized     = 21,
	Short2Normalized      = 22,
	Short3Normalized      = 23,
	Short4Normalized      = 24,
	Half2                 = 25,
	Half3                 = 26,
	Half4                 = 27,
	Float                 = 28,
	Float2                = 29,
	Float3                = 30,
	Float4                = 31,
	Int                   = 32,
	Int2                  = 33,
	Int3                  = 34,
	Int4                  = 35,
	UInt                  = 36,
	UInt2                 = 37,
	UInt3                 = 38,
	UInt4                 = 39,
	Int1010102Normalized  = 40,
	UInt1010102Normalized = 41,
	UChar4Normalized_BGRA = 42,
	UChar                 = 45,
	Char                  = 46,
	UCharNormalized       = 47,
	CharNormalized        = 48,
	UShort                = 49,
	Short                 = 50,
	UShortNormalized      = 51,
	ShortNormalized       = 52,
	Half                  = 53,
}

VertexStepFunction :: enum NS.UInteger {
	Constant             = 0,
	PerVertex            = 1,
	PerInstance          = 2,
	PerPatch             = 3,
	PerPatchControlPoint = 4,
}

ShaderValidation :: enum NS.UInteger {
	Default  = 0,
	Enabled  = 1,
	Disabled = 2,
}
