package directx_d3d12

foreign import "system:d3d12.lib"

import "../dxgi"
import "../d3d_compiler"
import win32 "core:sys/windows"

IUnknown        :: dxgi.IUnknown
IUnknown_VTable :: dxgi.IUnknown_VTable

HANDLE  :: dxgi.HANDLE
HMODULE :: dxgi.HMODULE
HRESULT :: dxgi.HRESULT
HWND    :: dxgi.HWND
LUID    :: dxgi.LUID
UUID    :: dxgi.UUID
GUID    :: dxgi.GUID
IID     :: dxgi.IID
SIZE_T  :: dxgi.SIZE_T
BOOL    :: dxgi.BOOL

RECT :: dxgi.RECT

IModuleInstance :: d3d_compiler.ID3D11ModuleInstance
IBlob           :: d3d_compiler.ID3DBlob
IModule         :: d3d_compiler.ID3D11Module

@(default_calling_convention="stdcall", link_prefix="D3D12")
foreign d3d12 {
	CreateDevice                             :: proc(pAdapter: ^IUnknown, MinimumFeatureLevel: FEATURE_LEVEL, riid: ^IID, ppDevice: ^rawptr) -> HRESULT ---
	CreateRootSignatureDeserializer          :: proc(pSrcData: rawptr, SrcDataSizeInBytes: SIZE_T, pRootSignatureDeserializerInterface: ^IID, ppRootSignatureDeserializer: ^rawptr) -> HRESULT ---
	CreateVersionedRootSignatureDeserializer :: proc(pSrcData: rawptr, SrcDataSizeInBytes: SIZE_T, pRootSignatureDeserializerInterface: ^IID, ppRootSignatureDeserializer: ^rawptr) -> HRESULT ---
	EnableExperimentalFeatures               :: proc(NumFeatures: u32, pIIDs: ^IID, pConfigurationStructs: rawptr, pConfigurationStructSizes: ^u32) -> HRESULT ---
	GetDebugInterface                        :: proc(riid: ^IID, ppvDebug: ^rawptr) -> HRESULT ---
	SerializeRootSignature                   :: proc(pRootSignature: ^ROOT_SIGNATURE_DESC, Version: ROOT_SIGNATURE_VERSION, ppBlob: ^^IBlob, ppErrorBlob: ^^IBlob) -> HRESULT ---
	SerializeVersionedRootSignature          :: proc(pRootSignature: ^VERSIONED_ROOT_SIGNATURE_DESC, ppBlob: ^^IBlob, ppErrorBlob: ^^IBlob) -> HRESULT ---
}

foreign d3d12 {
	WKPDID_D3DDebugObjectNameW: GUID
	WKPDID_CommentStringW:      GUID

	@(link_name="DXGI_DEBUG_D3D12")
	DEBUG_D3D12: GUID

	@(link_name="D3D12_PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED")
	PROTECTED_RESOURCES_SESSION_HARDWARE_PROTECTED: GUID
}

@(link_prefix="D3D_")
foreign d3d12 {
	TEXTURE_LAYOUT_ROW_MAJOR:             GUID
	TEXTURE_LAYOUT_64KB_STANDARD_SWIZZLE: GUID
}

@(link_prefix="D3D12")
foreign d3d12 {
	ExperimentalShaderModels: UUID
	TiledResourceTier4:       UUID
	MetaCommand:              UUID
}


DRIVER_TYPE :: enum i32 {
	UNKNOWN   = 0,
	HARDWARE  = 1,
	REFERENCE = 2,
	NULL      = 3,
	SOFTWARE  = 4,
	WARP      = 5,
}

FEATURE_LEVEL :: enum i32 {
	_1_0_CORE = 4096,
	_9_1      = 37120,
	_9_2      = 37376,
	_9_3      = 37632,
	_10_0     = 40960,
	_10_1     = 41216,
	_11_0     = 45056,
	_11_1     = 45312,
	_12_0     = 49152,
	_12_1     = 49408,
}

PRIMITIVE_TOPOLOGY :: enum i32 {
	UNDEFINED                   = 0,
	POINTLIST                   = 1,
	LINELIST                    = 2,
	LINESTRIP                   = 3,
	TRIANGLELIST                = 4,
	TRIANGLESTRIP               = 5,
	LINELIST_ADJ                = 10,
	LINESTRIP_ADJ               = 11,
	TRIANGLELIST_ADJ            = 12,
	TRIANGLESTRIP_ADJ           = 13,
	_1_CONTROL_POINT_PATCHLIST  = 33,
	_2_CONTROL_POINT_PATCHLIST  = 34,
	_3_CONTROL_POINT_PATCHLIST  = 35,
	_4_CONTROL_POINT_PATCHLIST  = 36,
	_5_CONTROL_POINT_PATCHLIST  = 37,
	_6_CONTROL_POINT_PATCHLIST  = 38,
	_7_CONTROL_POINT_PATCHLIST  = 39,
	_8_CONTROL_POINT_PATCHLIST  = 40,
	_9_CONTROL_POINT_PATCHLIST  = 41,
	_10_CONTROL_POINT_PATCHLIST = 42,
	_11_CONTROL_POINT_PATCHLIST = 43,
	_12_CONTROL_POINT_PATCHLIST = 44,
	_13_CONTROL_POINT_PATCHLIST = 45,
	_14_CONTROL_POINT_PATCHLIST = 46,
	_15_CONTROL_POINT_PATCHLIST = 47,
	_16_CONTROL_POINT_PATCHLIST = 48,
	_17_CONTROL_POINT_PATCHLIST = 49,
	_18_CONTROL_POINT_PATCHLIST = 50,
	_19_CONTROL_POINT_PATCHLIST = 51,
	_20_CONTROL_POINT_PATCHLIST = 52,
	_21_CONTROL_POINT_PATCHLIST = 53,
	_22_CONTROL_POINT_PATCHLIST = 54,
	_23_CONTROL_POINT_PATCHLIST = 55,
	_24_CONTROL_POINT_PATCHLIST = 56,
	_25_CONTROL_POINT_PATCHLIST = 57,
	_26_CONTROL_POINT_PATCHLIST = 58,
	_27_CONTROL_POINT_PATCHLIST = 59,
	_28_CONTROL_POINT_PATCHLIST = 60,
	_29_CONTROL_POINT_PATCHLIST = 61,
	_30_CONTROL_POINT_PATCHLIST = 62,
	_31_CONTROL_POINT_PATCHLIST = 63,
	_32_CONTROL_POINT_PATCHLIST = 64,
}

PRIMITIVE :: enum i32 {
	UNDEFINED               = 0,
	POINT                   = 1,
	LINE                    = 2,
	TRIANGLE                = 3,
	LINE_ADJ                = 6,
	TRIANGLE_ADJ            = 7,
	_1_CONTROL_POINT_PATCH  = 8,
	_2_CONTROL_POINT_PATCH  = 9,
	_3_CONTROL_POINT_PATCH  = 10,
	_4_CONTROL_POINT_PATCH  = 11,
	_5_CONTROL_POINT_PATCH  = 12,
	_6_CONTROL_POINT_PATCH  = 13,
	_7_CONTROL_POINT_PATCH  = 14,
	_8_CONTROL_POINT_PATCH  = 15,
	_9_CONTROL_POINT_PATCH  = 16,
	_10_CONTROL_POINT_PATCH = 17,
	_11_CONTROL_POINT_PATCH = 18,
	_12_CONTROL_POINT_PATCH = 19,
	_13_CONTROL_POINT_PATCH = 20,
	_14_CONTROL_POINT_PATCH = 21,
	_15_CONTROL_POINT_PATCH = 22,
	_16_CONTROL_POINT_PATCH = 23,
	_17_CONTROL_POINT_PATCH = 24,
	_18_CONTROL_POINT_PATCH = 25,
	_19_CONTROL_POINT_PATCH = 26,
	_20_CONTROL_POINT_PATCH = 27,
	_21_CONTROL_POINT_PATCH = 28,
	_22_CONTROL_POINT_PATCH = 29,
	_23_CONTROL_POINT_PATCH = 30,
	_24_CONTROL_POINT_PATCH = 31,
	_25_CONTROL_POINT_PATCH = 32,
	_26_CONTROL_POINT_PATCH = 33,
	_27_CONTROL_POINT_PATCH = 34,
	_28_CONTROL_POINT_PATCH = 35,
	_29_CONTROL_POINT_PATCH = 36,
	_30_CONTROL_POINT_PATCH = 37,
	_31_CONTROL_POINT_PATCH = 38,
	_32_CONTROL_POINT_PATCH = 39,
}

SRV_DIMENSION :: enum i32 {
	UNKNOWN          = 0,
	BUFFER           = 1,
	TEXTURE1D        = 2,
	TEXTURE1DARRAY   = 3,
	TEXTURE2D        = 4,
	TEXTURE2DARRAY   = 5,
	TEXTURE2DMS      = 6,
	TEXTURE2DMSARRAY = 7,
	TEXTURE3D        = 8,
	TEXTURECUBE      = 9,
	TEXTURECUBEARRAY = 10,
	BUFFEREX         = 11,
	RAYTRACING_ACCELERATION_STRUCTURE = 11,
}

PFN_DESTRUCTION_CALLBACK :: #type proc "c" (a0: rawptr)


ID3DDestructionNotifier_UUID :: "a06eb39a-50da-425b-8c31-4eecd6c270f3"
ID3DDestructionNotifier :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3ddestructionnotifier_vtable: ^ID3DDestructionNotifier_VTable,
}
ID3DDestructionNotifier_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	RegisterDestructionCallback:   proc "stdcall" (this: ^ID3DDestructionNotifier, callbackFn: PFN_DESTRUCTION_CALLBACK, pData: rawptr, pCallbackID: ^u32) -> HRESULT,
	UnregisterDestructionCallback: proc "stdcall" (this: ^ID3DDestructionNotifier, callbackID: u32) -> HRESULT,
}

SHADER_VARIABLE_CLASS :: enum i32 {
	SCALAR                = 0,
	VECTOR                = 1,
	MATRIX_ROWS           = 2,
	MATRIX_COLUMNS        = 3,
	OBJECT                = 4,
	STRUCT                = 5,
	INTERFACE_CLASS       = 6,
	INTERFACE_POINTER     = 7,
}

SHADER_VARIABLE_FLAGS :: enum u32 { // TODO: make bit_set
	USERPACKED              = 0x1,
	USED                    = 0x2,
	INTERFACE_POINTER       = 0x4,
	INTERFACE_PARAMETER     = 0x8,
}

SHADER_VARIABLE_TYPE :: enum i32 {
	VOID                          = 0,
	BOOL                          = 1,
	INT                           = 2,
	FLOAT                         = 3,
	STRING                        = 4,
	TEXTURE                       = 5,
	TEXTURE1D                     = 6,
	TEXTURE2D                     = 7,
	TEXTURE3D                     = 8,
	TEXTURECUBE                   = 9,
	SAMPLER                       = 10,
	SAMPLER1D                     = 11,
	SAMPLER2D                     = 12,
	SAMPLER3D                     = 13,
	SAMPLERCUBE                   = 14,
	PIXELSHADER                   = 15,
	VERTEXSHADER                  = 16,
	PIXELFRAGMENT                 = 17,
	VERTEXFRAGMENT                = 18,
	UINT                          = 19,
	UINT8                         = 20,
	GEOMETRYSHADER                = 21,
	RASTERIZER                    = 22,
	DEPTHSTENCIL                  = 23,
	BLEND                         = 24,
	BUFFER                        = 25,
	CBUFFER                       = 26,
	TBUFFER                       = 27,
	TEXTURE1DARRAY                = 28,
	TEXTURE2DARRAY                = 29,
	RENDERTARGETVIEW              = 30,
	DEPTHSTENCILVIEW              = 31,
	TEXTURE2DMS                   = 32,
	TEXTURE2DMSARRAY              = 33,
	TEXTURECUBEARRAY              = 34,
	HULLSHADER                    = 35,
	DOMAINSHADER                  = 36,
	INTERFACE_POINTER             = 37,
	COMPUTESHADER                 = 38,
	DOUBLE                        = 39,
	RWTEXTURE1D                   = 40,
	RWTEXTURE1DARRAY              = 41,
	RWTEXTURE2D                   = 42,
	RWTEXTURE2DARRAY              = 43,
	RWTEXTURE3D                   = 44,
	RWBUFFER                      = 45,
	BYTEADDRESS_BUFFER            = 46,
	RWBYTEADDRESS_BUFFER          = 47,
	STRUCTURED_BUFFER             = 48,
	RWSTRUCTURED_BUFFER           = 49,
	APPEND_STRUCTURED_BUFFER      = 50,
	CONSUME_STRUCTURED_BUFFER     = 51,
	MIN8FLOAT                     = 52,
	MIN10FLOAT                    = 53,
	MIN16FLOAT                    = 54,
	MIN12INT                      = 55,
	MIN16INT                      = 56,
	MIN16UINT                     = 57,
}

SHADER_INPUT_FLAGS :: enum u32 { // TODO: make bit_set
	USERPACKED              = 0x1,
	COMPARISON_SAMPLER      = 0x2,
	TEXTURE_COMPONENT_0     = 0x4,
	TEXTURE_COMPONENT_1     = 0x8,
	TEXTURE_COMPONENTS      = 0xc,
	UNUSED                  = 0x10,
}

SHADER_INPUT_TYPE :: enum i32 {
	CBUFFER                        = 0,
	TBUFFER                        = 1,
	TEXTURE                        = 2,
	SAMPLER                        = 3,
	UAV_RWTYPED                    = 4,
	STRUCTURED                     = 5,
	UAV_RWSTRUCTURED               = 6,
	BYTEADDRESS                    = 7,
	UAV_RWBYTEADDRESS              = 8,
	UAV_APPEND_STRUCTURED          = 9,
	UAV_CONSUME_STRUCTURED         = 10,
	UAV_RWSTRUCTURED_WITH_COUNTER  = 11,
	RTACCELERATIONSTRUCTURE        = 12,
	UAV_FEEDBACKTEXTURE            = 13,
}

SHADER_CBUFFER_FLAGS :: enum u32 { // TODO: make bit_set
	USERPACKED = 0x1,
}

CBUFFER_TYPE :: enum i32 {
	CBUFFER            = 0,
	TBUFFER            = 1,
	INTERFACE_POINTERS = 2,
	RESOURCE_BIND_INFO = 3,
}

NAME :: enum i32 {
	UNDEFINED                     = 0,
	POSITION                      = 1,
	CLIP_DISTANCE                 = 2,
	CULL_DISTANCE                 = 3,
	RENDER_TARGET_ARRAY_INDEX     = 4,
	VIEWPORT_ARRAY_INDEX          = 5,
	VERTEX_ID                     = 6,
	PRIMITIVE_ID                  = 7,
	INSTANCE_ID                   = 8,
	IS_FRONT_FACE                 = 9,
	SAMPLE_INDEX                  = 10,
	FINAL_QUAD_EDGE_TESSFACTOR    = 11,
	FINAL_QUAD_INSIDE_TESSFACTOR  = 12,
	FINAL_TRI_EDGE_TESSFACTOR     = 13,
	FINAL_TRI_INSIDE_TESSFACTOR   = 14,
	FINAL_LINE_DETAIL_TESSFACTOR  = 15,
	FINAL_LINE_DENSITY_TESSFACTOR = 16,
	BARYCENTRICS                  = 23,
	SHADINGRATE                   = 24,
	CULLPRIMITIVE                 = 25,
	TARGET                        = 64,
	DEPTH                         = 65,
	COVERAGE                      = 66,
	DEPTH_GREATER_EQUAL           = 67,
	DEPTH_LESS_EQUAL              = 68,
	STENCIL_REF                   = 69,
	INNER_COVERAGE                = 70,
}

RESOURCE_RETURN_TYPE :: enum i32 {
	UNORM         = 1,
	SNORM         = 2,
	SINT          = 3,
	UINT          = 4,
	FLOAT         = 5,
	MIXED         = 6,
	DOUBLE        = 7,
	CONTINUED     = 8,
}

REGISTER_COMPONENT_TYPE :: enum i32 {
	UNKNOWN     = 0,
	UINT32      = 1,
	SINT32      = 2,
	FLOAT32     = 3,
}

TESSELLATOR_DOMAIN :: enum i32 {
	UNDEFINED = 0,
	ISOLINE   = 1,
	TRI       = 2,
	QUAD      = 3,
}

TESSELLATOR_PARTITIONING :: enum i32 {
	UNDEFINED       = 0,
	INTEGER         = 1,
	POW2            = 2,
	FRACTIONAL_ODD  = 3,
	FRACTIONAL_EVEN = 4,
}

TESSELLATOR_OUTPUT_PRIMITIVE :: enum i32 {
	UNDEFINED        = 0,
	POINT            = 1,
	LINE             = 2,
	TRIANGLE_CW      = 3,
	TRIANGLE_CCW     = 4,
}

MIN_PRECISION :: enum i32 {
	DEFAULT   = 0,
	FLOAT_16  = 1,
	FLOAT_2_8 = 2,
	RESERVED  = 3,
	SINT_16   = 4,
	UINT_16   = 5,
	ANY_16    = 240,
	ANY_10    = 241,
}

INTERPOLATION_MODE :: enum i32 {
	UNDEFINED                     = 0,
	CONSTANT                      = 1,
	LINEAR                        = 2,
	LINEAR_CENTROID               = 3,
	LINEAR_NOPERSPECTIVE          = 4,
	LINEAR_NOPERSPECTIVE_CENTROID = 5,
	LINEAR_SAMPLE                 = 6,
	LINEAR_NOPERSPECTIVE_SAMPLE   = 7,
}

PARAMETER_FLAGS :: enum u32 { // TODO: make bit_set
	NONE = 0x0,
	IN   = 0x1,
	OUT  = 0x2,
}


GPU_VIRTUAL_ADDRESS :: u64

COMMAND_LIST_TYPE :: enum i32 {
	DIRECT        = 0,
	BUNDLE        = 1,
	COMPUTE       = 2,
	COPY          = 3,
	VIDEO_DECODE  = 4,
	VIDEO_PROCESS = 5,
	VIDEO_ENCODE  = 6,
}

COMMAND_QUEUE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                = 0x0,
	DISABLE_GPU_TIMEOUT = 0x1,
}

COMMAND_QUEUE_PRIORITY :: enum i32 {
	NORMAL          = 0,
	HIGH            = 100,
	GLOBAL_REALTIME = 10000,
}

COMMAND_QUEUE_DESC :: struct {
	Type:     COMMAND_LIST_TYPE,
	Priority: i32,
	Flags:    COMMAND_QUEUE_FLAGS,
	NodeMask: u32,
}

PRIMITIVE_TOPOLOGY_TYPE :: enum i32 {
	UNDEFINED = 0,
	POINT     = 1,
	LINE      = 2,
	TRIANGLE  = 3,
	PATCH     = 4,
}

INPUT_CLASSIFICATION :: enum i32 {
	PER_VERTEX_DATA   = 0,
	PER_INSTANCE_DATA = 1,
}

INPUT_ELEMENT_DESC :: struct {
	SemanticName:         cstring,
	SemanticIndex:        u32,
	Format:               dxgi.FORMAT,
	InputSlot:            u32,
	AlignedByteOffset:    u32,
	InputSlotClass:       INPUT_CLASSIFICATION,
	InstanceDataStepRate: u32,
}

FILL_MODE :: enum i32 {
	WIREFRAME = 2,
	SOLID     = 3,
}

CULL_MODE :: enum i32 {
	NONE  = 1,
	FRONT = 2,
	BACK  = 3,
}

SO_DECLARATION_ENTRY :: struct {
	Stream:         u32,
	SemanticName:   cstring,
	SemanticIndex:  u32,
	StartComponent: u8,
	ComponentCount: u8,
	OutputSlot:     u8,
}

VIEWPORT :: struct {
	TopLeftX: f32,
	TopLeftY: f32,
	Width:    f32,
	Height:   f32,
	MinDepth: f32,
	MaxDepth: f32,
}

BOX :: struct {
	left:   u32,
	top:    u32,
	front:  u32,
	right:  u32,
	bottom: u32,
	back:   u32,
}

COMPARISON_FUNC :: enum i32 {
	NEVER         = 1,
	LESS          = 2,
	EQUAL         = 3,
	LESS_EQUAL    = 4,
	GREATER       = 5,
	NOT_EQUAL     = 6,
	GREATER_EQUAL = 7,
	ALWAYS        = 8,
}

DEPTH_WRITE_MASK :: enum i32 {
	ZERO = 0,
	ALL  = 1,
}

STENCIL_OP :: enum i32 {
	KEEP     = 1,
	ZERO     = 2,
	REPLACE  = 3,
	INCR_SAT = 4,
	DECR_SAT = 5,
	INVERT   = 6,
	INCR     = 7,
	DECR     = 8,
}

DEPTH_STENCILOP_DESC :: struct {
	StencilFailOp:      STENCIL_OP,
	StencilDepthFailOp: STENCIL_OP,
	StencilPassOp:      STENCIL_OP,
	StencilFunc:        COMPARISON_FUNC,
}

DEPTH_STENCIL_DESC :: struct {
	DepthEnable:      BOOL,
	DepthWriteMask:   DEPTH_WRITE_MASK,
	DepthFunc:        COMPARISON_FUNC,
	StencilEnable:    BOOL,
	StencilReadMask:  u8,
	StencilWriteMask: u8,
	FrontFace:        DEPTH_STENCILOP_DESC,
	BackFace:         DEPTH_STENCILOP_DESC,
}

DEPTH_STENCIL_DESC1 :: struct {
	DepthEnable:           BOOL,
	DepthWriteMask:        DEPTH_WRITE_MASK,
	DepthFunc:             COMPARISON_FUNC,
	StencilEnable:         BOOL,
	StencilReadMask:       u8,
	StencilWriteMask:      u8,
	FrontFace:             DEPTH_STENCILOP_DESC,
	BackFace:              DEPTH_STENCILOP_DESC,
	DepthBoundsTestEnable: BOOL,
}

BLEND :: enum i32 {
	ZERO             = 1,
	ONE              = 2,
	SRC_COLOR        = 3,
	INV_SRC_COLOR    = 4,
	SRC_ALPHA        = 5,
	INV_SRC_ALPHA    = 6,
	DEST_ALPHA       = 7,
	INV_DEST_ALPHA   = 8,
	DEST_COLOR       = 9,
	INV_DEST_COLOR   = 10,
	SRC_ALPHA_SAT    = 11,
	BLEND_FACTOR     = 14,
	INV_BLEND_FACTOR = 15,
	SRC1_COLOR       = 16,
	INV_SRC1_COLOR   = 17,
	SRC1_ALPHA       = 18,
	INV_SRC1_ALPHA   = 19,
}

BLEND_OP :: enum i32 {
	ADD          = 1,
	SUBTRACT     = 2,
	REV_SUBTRACT = 3,
	MIN          = 4,
	MAX          = 5,
}

COLOR_WRITE_ENABLE :: enum i32 { // TODO: make bit_set
	RED   = 1,
	GREEN = 2,
	BLUE  = 4,
	ALPHA = 8,
	ALL   = 15,
}

LOGIC_OP :: enum i32 {
	CLEAR         = 0,
	SET           = 1,
	COPY          = 2,
	COPY_INVERTED = 3,
	NOOP          = 4,
	INVERT        = 5,
	AND           = 6,
	NAND          = 7,
	OR            = 8,
	NOR           = 9,
	XOR           = 10,
	EQUIV         = 11,
	AND_REVERSE   = 12,
	AND_INVERTED  = 13,
	OR_REVERSE    = 14,
	OR_INVERTED   = 15,
}

RENDER_TARGET_BLEND_DESC :: struct {
	BlendEnable:           BOOL,
	LogicOpEnable:         BOOL,
	SrcBlend:              BLEND,
	DestBlend:             BLEND,
	BlendOp:               BLEND_OP,
	SrcBlendAlpha:         BLEND,
	DestBlendAlpha:        BLEND,
	BlendOpAlpha:          BLEND_OP,
	LogicOp:               LOGIC_OP,
	RenderTargetWriteMask: u8,
}

BLEND_DESC :: struct {
	AlphaToCoverageEnable:  BOOL,
	IndependentBlendEnable: BOOL,
	RenderTarget:           [8]RENDER_TARGET_BLEND_DESC,
}

CONSERVATIVE_RASTERIZATION_MODE :: enum i32 {
	OFF = 0,
	ON  = 1,
}

RASTERIZER_DESC :: struct {
	FillMode:              FILL_MODE,
	CullMode:              CULL_MODE,
	FrontCounterClockwise: BOOL,
	DepthBias:             i32,
	DepthBiasClamp:        f32,
	SlopeScaledDepthBias:  f32,
	DepthClipEnable:       BOOL,
	MultisampleEnable:     BOOL,
	AntialiasedLineEnable: BOOL,
	ForcedSampleCount:     u32,
	ConservativeRaster:    CONSERVATIVE_RASTERIZATION_MODE,
}


IObject_UUID :: "c4fec28f-7966-4e95-9f94-f431cb56c3b8"
IObject :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12object_vtable: ^IObject_VTable,
}
IObject_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetPrivateData:          proc "stdcall" (this: ^IObject, guid: ^GUID, pDataSize: ^u32, pData: rawptr) -> HRESULT,
	SetPrivateData:          proc "stdcall" (this: ^IObject, guid: ^GUID, DataSize: u32, pData: rawptr) -> HRESULT,
	SetPrivateDataInterface: proc "stdcall" (this: ^IObject, guid: ^GUID, pData: ^IUnknown) -> HRESULT,
	SetName:                 proc "stdcall" (this: ^IObject, Name: [^]u16) -> HRESULT,
}


IDeviceChild_UUID :: "905db94b-a00c-4140-9df5-2b64ca9ea357"
IDeviceChild :: struct #raw_union {
	#subtype id3d12object: IObject,
	using id3d12devicechild_vtable: ^IDeviceChild_VTable,
}
IDeviceChild_VTable :: struct {
	using id3d12object_vtable: IObject_VTable,
	GetDevice: proc "stdcall" (this: ^IDeviceChild, riid: ^IID, ppvDevice: ^rawptr) -> HRESULT,
}


IRootSignature_UUID :: "c54a6b66-72df-4ee8-8be5-a946a1429214"
IRootSignature :: struct {
	using id3d12devicechild: IDeviceChild,
}

SHADER_BYTECODE :: struct {
	pShaderBytecode: rawptr,
	BytecodeLength:  SIZE_T,
}

STREAM_OUTPUT_DESC :: struct {
	pSODeclaration:   ^SO_DECLARATION_ENTRY,
	NumEntries:       u32,
	pBufferStrides:   ^u32,
	NumStrides:       u32,
	RasterizedStream: u32,
}

INPUT_LAYOUT_DESC :: struct {
	pInputElementDescs: ^INPUT_ELEMENT_DESC,
	NumElements:        u32,
}

INDEX_BUFFER_STRIP_CUT_VALUE :: enum i32 {
	DISABLED    = 0,
	_0xFFFF     = 1,
	_0xFFFFFFFF = 2,
}

CACHED_PIPELINE_STATE :: struct {
	pCachedBlob:           rawptr,
	CachedBlobSizeInBytes: SIZE_T,
}

PIPELINE_STATE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE       = 0x0,
	TOOL_DEBUG = 0x1,
}

GRAPHICS_PIPELINE_STATE_DESC :: struct {
	pRootSignature:        ^IRootSignature,
	VS:                    SHADER_BYTECODE,
	PS:                    SHADER_BYTECODE,
	DS:                    SHADER_BYTECODE,
	HS:                    SHADER_BYTECODE,
	GS:                    SHADER_BYTECODE,
	StreamOutput:          STREAM_OUTPUT_DESC,
	BlendState:            BLEND_DESC,
	SampleMask:            u32,
	RasterizerState:       RASTERIZER_DESC,
	DepthStencilState:     DEPTH_STENCIL_DESC,
	InputLayout:           INPUT_LAYOUT_DESC,
	IBStripCutValue:       INDEX_BUFFER_STRIP_CUT_VALUE,
	PrimitiveTopologyType: PRIMITIVE_TOPOLOGY_TYPE,
	NumRenderTargets:      u32,
	RTVFormats:            [8]dxgi.FORMAT,
	DSVFormat:             dxgi.FORMAT,
	SampleDesc:            dxgi.SAMPLE_DESC,
	NodeMask:              u32,
	CachedPSO:             CACHED_PIPELINE_STATE,
	Flags:                 PIPELINE_STATE_FLAGS,
}

COMPUTE_PIPELINE_STATE_DESC :: struct {
	pRootSignature: ^IRootSignature,
	CS:             SHADER_BYTECODE,
	NodeMask:       u32,
	CachedPSO:      CACHED_PIPELINE_STATE,
	Flags:          PIPELINE_STATE_FLAGS,
}

RT_FORMAT_ARRAY :: struct {
	RTFormats:        [8]dxgi.FORMAT,
	NumRenderTargets: u32,
}

PIPELINE_STATE_STREAM_DESC :: struct {
	SizeInBytes:                   SIZE_T,
	pPipelineStateSubobjectStream: rawptr,
}

PIPELINE_STATE_SUBOBJECT_TYPE :: enum i32 {
	ROOT_SIGNATURE        = 0,
	VS                    = 1,
	PS                    = 2,
	DS                    = 3,
	HS                    = 4,
	GS                    = 5,
	CS                    = 6,
	STREAM_OUTPUT         = 7,
	BLEND                 = 8,
	SAMPLE_MASK           = 9,
	RASTERIZER            = 10,
	DEPTH_STENCIL         = 11,
	INPUT_LAYOUT          = 12,
	IB_STRIP_CUT_VALUE    = 13,
	PRIMITIVE_TOPOLOGY    = 14,
	RENDER_TARGET_FORMATS = 15,
	DEPTH_STENCIL_FORMAT  = 16,
	SAMPLE_DESC           = 17,
	NODE_MASK             = 18,
	CACHED_PSO            = 19,
	FLAGS                 = 20,
	DEPTH_STENCIL1        = 21,
	VIEW_INSTANCING       = 22,
	AS                    = 24,
	MS                    = 25,
	MAX_VALID             = 26,
}

FEATURE :: enum i32 {
	OPTIONS                               = 0,
	ARCHITECTURE                          = 1,
	FEATURE_LEVELS                        = 2,
	FORMAT_SUPPORT                        = 3,
	MULTISAMPLE_QUALITY_LEVELS            = 4,
	FORMAT_INFO                           = 5,
	GPU_VIRTUAL_ADDRESS_SUPPORT           = 6,
	SHADER_MODEL                          = 7,
	OPTIONS1                              = 8,
	PROTECTED_RESOURCE_SESSION_SUPPORT    = 10,
	ROOT_SIGNATURE                        = 12,
	ARCHITECTURE1                         = 16,
	OPTIONS2                              = 18,
	SHADER_CACHE                          = 19,
	COMMAND_QUEUE_PRIORITY                = 20,
	OPTIONS3                              = 21,
	EXISTING_HEAPS                        = 22,
	OPTIONS4                              = 23,
	SERIALIZATION                         = 24,
	CROSS_NODE                            = 25,
	OPTIONS5                              = 27,
	OPTIONS6                              = 30,
	QUERY_META_COMMAND                    = 31,
	OPTIONS7                              = 32,
	PROTECTED_RESOURCE_SESSION_TYPE_COUNT = 33,
	PROTECTED_RESOURCE_SESSION_TYPES      = 34,
}

SHADER_MIN_PRECISION_SUPPORT :: enum i32 {
	NONE    = 0,
	_10_BIT = 1,
	_16_BIT = 2,
}

TILED_RESOURCES_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1            = 1,
	_2            = 2,
	_3            = 3,
	_4            = 4,
}

RESOURCE_BINDING_TIER :: enum i32 {
	_1 = 1,
	_2 = 2,
	_3 = 3,
}

CONSERVATIVE_RASTERIZATION_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1            = 1,
	_2            = 2,
	_3            = 3,
}

FORMAT_SUPPORT1 :: enum i32 { // TODO: make bit_set
	NONE                        = 0,
	BUFFER                      = 1,
	IA_VERTEX_BUFFER            = 2,
	IA_INDEX_BUFFER             = 4,
	SO_BUFFER                   = 8,
	TEXTURE1D                   = 16,
	TEXTURE2D                   = 32,
	TEXTURE3D                   = 64,
	TEXTURECUBE                 = 128,
	SHADER_LOAD                 = 256,
	SHADER_SAMPLE               = 512,
	SHADER_SAMPLE_COMPARISON    = 1024,
	SHADER_SAMPLE_MONO_TEXT     = 2048,
	MIP                         = 4096,
	RENDER_TARGET               = 16384,
	BLENDABLE                   = 32768,
	DEPTH_STENCIL               = 65536,
	MULTISAMPLE_RESOLVE         = 262144,
	DISPLAY                     = 524288,
	CAST_WITHIN_BIT_LAYOUT      = 1048576,
	MULTISAMPLE_RENDERTARGET    = 2097152,
	MULTISAMPLE_LOAD            = 4194304,
	SHADER_GATHER               = 8388608,
	BACK_BUFFER_CAST            = 16777216,
	TYPED_UNORDERED_ACCESS_VIEW = 33554432,
	SHADER_GATHER_COMPARISON    = 67108864,
	DECODER_OUTPUT              = 134217728,
	VIDEO_PROCESSOR_OUTPUT      = 268435456,
	VIDEO_PROCESSOR_INPUT       = 536870912,
	VIDEO_ENCODER               = 1073741824,
}

FORMAT_SUPPORT2 :: enum i32 { // TODO: make bit_set
	NONE                                         = 0,
	UAV_ATOMIC_ADD                               = 1,
	UAV_ATOMIC_BITWISE_OPS                       = 2,
	UAV_ATOMIC_COMPARE_STORE_OR_COMPARE_EXCHANGE = 4,
	UAV_ATOMIC_EXCHANGE                          = 8,
	UAV_ATOMIC_SIGNED_MIN_OR_MAX                 = 16,
	UAV_ATOMIC_UNSIGNED_MIN_OR_MAX               = 32,
	UAV_TYPED_LOAD                               = 64,
	UAV_TYPED_STORE                              = 128,
	OUTPUT_MERGER_LOGIC_OP                       = 256,
	TILED                                        = 512,
	MULTIPLANE_OVERLAY                           = 16384,
	SAMPLER_FEEDBACK                             = 32768,
}

MULTISAMPLE_QUALITY_LEVEL_FLAGS :: enum u32 { // TODO: make bit_set
	NONE           = 0x0,
	TILED_RESOURCE = 0x1,
}

CROSS_NODE_SHARING_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1_EMULATED   = 1,
	_1            = 2,
	_2            = 3,
	_3            = 4,
}

RESOURCE_HEAP_TIER :: enum i32 {
	_1 = 1,
	_2 = 2,
}

PROGRAMMABLE_SAMPLE_POSITIONS_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1            = 1,
	_2            = 2,
}

VIEW_INSTANCING_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1            = 1,
	_2            = 2,
	_3            = 3,
}

FEATURE_DATA_OPTIONS :: struct {
	DoublePrecisionFloatShaderOps:                                              BOOL,
	OutputMergerLogicOp:                                                        BOOL,
	MinPrecisionSupport:                                                        SHADER_MIN_PRECISION_SUPPORT,
	TiledResourcesTier:                                                         TILED_RESOURCES_TIER,
	ResourceBindingTier:                                                        RESOURCE_BINDING_TIER,
	PSSpecifiedStencilRefSupported:                                             BOOL,
	TypedUAVLoadAdditionalFormats:                                              BOOL,
	ROVsSupported:                                                              BOOL,
	ConservativeRasterizationTier:                                              CONSERVATIVE_RASTERIZATION_TIER,
	MaxGPUVirtualAddressBitsPerResource:                                        u32,
	StandardSwizzle64KBSupported:                                               BOOL,
	CrossNodeSharingTier:                                                       CROSS_NODE_SHARING_TIER,
	CrossAdapterRowMajorTextureSupported:                                       BOOL,
	VPAndRTArrayIndexFromAnyShaderFeedingRasterizerSupportedWithoutGSEmulation: BOOL,
	ResourceHeapTier:                                                           RESOURCE_HEAP_TIER,
}

FEATURE_DATA_OPTIONS1 :: struct {
	WaveOps:                       BOOL,
	WaveLaneCountMin:              u32,
	WaveLaneCountMax:              u32,
	TotalLaneCount:                u32,
	ExpandedComputeResourceStates: BOOL,
	Int64ShaderOps:                BOOL,
}

FEATURE_DATA_OPTIONS2 :: struct {
	DepthBoundsTestSupported:        BOOL,
	ProgrammableSamplePositionsTier: PROGRAMMABLE_SAMPLE_POSITIONS_TIER,
}

ROOT_SIGNATURE_VERSION :: enum i32 {
	_1   = 1,
	_1_0 = 1,
	_1_1 = 2,
}

FEATURE_DATA_ROOT_SIGNATURE :: struct {
	HighestVersion: ROOT_SIGNATURE_VERSION,
}

FEATURE_DATA_ARCHITECTURE :: struct {
	NodeIndex:         u32,
	TileBasedRenderer: BOOL,
	UMA:               BOOL,
	CacheCoherentUMA:  BOOL,
}

FEATURE_DATA_ARCHITECTURE1 :: struct {
	NodeIndex:         u32,
	TileBasedRenderer: BOOL,
	UMA:               BOOL,
	CacheCoherentUMA:  BOOL,
	IsolatedMMU:       BOOL,
}

FEATURE_DATA_FEATURE_LEVELS :: struct {
	NumFeatureLevels:         u32,
	pFeatureLevelsRequested:  ^FEATURE_LEVEL,
	MaxSupportedFeatureLevel: FEATURE_LEVEL,
}

SHADER_MODEL :: enum i32 {
	_5_1 = 81,
	_6_0 = 96,
	_6_1 = 97,
	_6_2 = 98,
	_6_3 = 99,
	_6_4 = 100,
	_6_5 = 101,
	_6_6 = 102,
}

FEATURE_DATA_SHADER_MODEL :: struct {
	HighestShaderModel: SHADER_MODEL,
}

FEATURE_DATA_FORMAT_SUPPORT :: struct {
	Format:   dxgi.FORMAT,
	Support1: FORMAT_SUPPORT1,
	Support2: FORMAT_SUPPORT2,
}

FEATURE_DATA_MULTISAMPLE_QUALITY_LEVELS :: struct {
	Format:           dxgi.FORMAT,
	SampleCount:      u32,
	Flags:            MULTISAMPLE_QUALITY_LEVEL_FLAGS,
	NumQualityLevels: u32,
}

FEATURE_DATA_FORMAT_INFO :: struct {
	Format:     dxgi.FORMAT,
	PlaneCount: u8,
}

FEATURE_DATA_GPU_VIRTUAL_ADDRESS_SUPPORT :: struct {
	MaxGPUVirtualAddressBitsPerResource: u32,
	MaxGPUVirtualAddressBitsPerProcess:  u32,
}

SHADER_CACHE_SUPPORT_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                   = 0x0,
	SINGLE_PSO             = 0x1,
	LIBRARY                = 0x2,
	AUTOMATIC_INPROC_CACHE = 0x4,
	AUTOMATIC_DISK_CACHE   = 0x8,
}

FEATURE_DATA_SHADER_CACHE :: struct {
	SupportFlags: SHADER_CACHE_SUPPORT_FLAGS,
}

FEATURE_DATA_COMMAND_QUEUE_PRIORITY :: struct {
	CommandListType:            COMMAND_LIST_TYPE,
	Priority:                   u32,
	PriorityForTypeIsSupported: BOOL,
}

COMMAND_LIST_SUPPORT_FLAGS :: enum u32 { // TODO: make bit_set
	NONE          = 0x0,
	DIRECT        = 0x1,
	BUNDLE        = 0x2,
	COMPUTE       = 0x4,
	COPY          = 0x8,
	VIDEO_DECODE  = 0x10,
	VIDEO_PROCESS = 0x20,
	VIDEO_ENCODE  = 0x40,
}

FEATURE_DATA_OPTIONS3 :: struct {
	CopyQueueTimestampQueriesSupported: BOOL,
	CastingFullyTypedFormatSupported:   BOOL,
	WriteBufferImmediateSupportFlags:   COMMAND_LIST_SUPPORT_FLAGS,
	ViewInstancingTier:                 VIEW_INSTANCING_TIER,
	BarycentricsSupported:              BOOL,
}

FEATURE_DATA_EXISTING_HEAPS :: struct {
	Supported: BOOL,
}

SHARED_RESOURCE_COMPATIBILITY_TIER :: enum i32 {
	_0 = 0,
	_1 = 1,
	_2 = 2,
}

FEATURE_DATA_OPTIONS4 :: struct {
	MSAA64KBAlignedTextureSupported: BOOL,
	SharedResourceCompatibilityTier: SHARED_RESOURCE_COMPATIBILITY_TIER,
	Native16BitShaderOpsSupported:   BOOL,
}

HEAP_SERIALIZATION_TIER :: enum i32 {
	_0  = 0,
	_10 = 10,
}

FEATURE_DATA_SERIALIZATION :: struct {
	NodeIndex:             u32,
	HeapSerializationTier: HEAP_SERIALIZATION_TIER,
}

FEATURE_DATA_CROSS_NODE :: struct {
	SharingTier:              CROSS_NODE_SHARING_TIER,
	AtomicShaderInstructions: BOOL,
}

RENDER_PASS_TIER :: enum i32 {
	_0 = 0,
	_1 = 1,
	_2 = 2,
}

RAYTRACING_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1_0          = 10,
	_1_1          = 11,
}

FEATURE_DATA_OPTIONS5 :: struct {
	SRVOnlyTiledResourceTier3: BOOL,
	RenderPassesTier:          RENDER_PASS_TIER,
	RaytracingTier:            RAYTRACING_TIER,
}

VARIABLE_SHADING_RATE_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1            = 1,
	_2            = 2,
}

FEATURE_DATA_OPTIONS6 :: struct {
	AdditionalShadingRatesSupported:                      BOOL,
	PerPrimitiveShadingRateSupportedWithViewportIndexing: BOOL,
	VariableShadingRateTier:                              VARIABLE_SHADING_RATE_TIER,
	ShadingRateImageTileSize:                             u32,
	BackgroundProcessingSupported:                        BOOL,
}

MESH_SHADER_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_1            = 10,
}

SAMPLER_FEEDBACK_TIER :: enum i32 {
	NOT_SUPPORTED = 0,
	_0_9          = 90,
	_1_0          = 100,
}

FEATURE_DATA_OPTIONS7 :: struct {
	MeshShaderTier:      MESH_SHADER_TIER,
	SamplerFeedbackTier: SAMPLER_FEEDBACK_TIER,
}

FEATURE_DATA_QUERY_META_COMMAND :: struct {
	CommandId:                  GUID,
	NodeMask:                   u32,
	pQueryInputData:            rawptr,
	QueryInputDataSizeInBytes:  SIZE_T,
	pQueryOutputData:           rawptr,
	QueryOutputDataSizeInBytes: SIZE_T,
}

RESOURCE_ALLOCATION_INFO :: struct {
	SizeInBytes: u64,
	Alignment:   u64,
}

RESOURCE_ALLOCATION_INFO1 :: struct {
	Offset:      u64,
	Alignment:   u64,
	SizeInBytes: u64,
}

HEAP_TYPE :: enum i32 {
	DEFAULT  = 1,
	UPLOAD   = 2,
	READBACK = 3,
	CUSTOM   = 4,
}

CPU_PAGE_PROPERTY :: enum i32 {
	UNKNOWN       = 0,
	NOT_AVAILABLE = 1,
	WRITE_COMBINE = 2,
	WRITE_BACK    = 3,
}

MEMORY_POOL :: enum i32 {
	UNKNOWN = 0,
	L0      = 1,
	L1      = 2,
}

HEAP_PROPERTIES :: struct {
	Type:                 HEAP_TYPE,
	CPUPageProperty:      CPU_PAGE_PROPERTY,
	MemoryPoolPreference: MEMORY_POOL,
	CreationNodeMask:     u32,
	VisibleNodeMask:      u32,
}

HEAP_FLAGS :: enum u32 { // TODO: make bit_set ???
	NONE                           = 0x0,
	SHARED                         = 0x1,
	DENY_BUFFERS                   = 0x4,
	ALLOW_DISPLAY                  = 0x8,
	SHARED_CROSS_ADAPTER           = 0x20,
	DENY_RT_DS_TEXTURES            = 0x40,
	DENY_NON_RT_DS_TEXTURES        = 0x80,
	HARDWARE_PROTECTED             = 0x100,
	ALLOW_WRITE_WATCH              = 0x200,
	ALLOW_SHADER_ATOMICS           = 0x400,
	CREATE_NOT_RESIDENT            = 0x800,
	CREATE_NOT_ZEROED              = 0x1000,
	ALLOW_ALL_BUFFERS_AND_TEXTURES = 0x0,
	ALLOW_ONLY_BUFFERS             = 0xc0,
	ALLOW_ONLY_NON_RT_DS_TEXTURES  = 0x44,
	ALLOW_ONLY_RT_DS_TEXTURES      = 0x84,
}

HEAP_DESC :: struct {
	SizeInBytes: u64,
	Properties:  HEAP_PROPERTIES,
	Alignment:   u64,
	Flags:       HEAP_FLAGS,
}

RESOURCE_DIMENSION :: enum i32 {
	UNKNOWN   = 0,
	BUFFER    = 1,
	TEXTURE1D = 2,
	TEXTURE2D = 3,
	TEXTURE3D = 4,
}

TEXTURE_LAYOUT :: enum i32 {
	UNKNOWN                 = 0,
	ROW_MAJOR               = 1,
	_64KB_UNDEFINED_SWIZZLE = 2,
	_64KB_STANDARD_SWIZZLE  = 3,
}

RESOURCE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                        = 0x0,
	ALLOW_RENDER_TARGET         = 0x1,
	ALLOW_DEPTH_STENCIL         = 0x2,
	ALLOW_UNORDERED_ACCESS      = 0x4,
	DENY_SHADER_RESOURCE        = 0x8,
	ALLOW_CROSS_ADAPTER         = 0x10,
	ALLOW_SIMULTANEOUS_ACCESS   = 0x20,
	VIDEO_DECODE_REFERENCE_ONLY = 0x40,
}

MIP_REGION :: struct {
	Width:  u32,
	Height: u32,
	Depth:  u32,
}

RESOURCE_DESC :: struct {
	Dimension:        RESOURCE_DIMENSION,
	Alignment:        u64,
	Width:            u64,
	Height:           u32,
	DepthOrArraySize: u16,
	MipLevels:        u16,
	Format:           dxgi.FORMAT,
	SampleDesc:       dxgi.SAMPLE_DESC,
	Layout:           TEXTURE_LAYOUT,
	Flags:            RESOURCE_FLAGS,
}

RESOURCE_DESC1 :: struct {
	Dimension:                RESOURCE_DIMENSION,
	Alignment:                u64,
	Width:                    u64,
	Height:                   u32,
	DepthOrArraySize:         u16,
	MipLevels:                u16,
	Format:                   dxgi.FORMAT,
	SampleDesc:               dxgi.SAMPLE_DESC,
	Layout:                   TEXTURE_LAYOUT,
	Flags:                    RESOURCE_FLAGS,
	SamplerFeedbackMipRegion: MIP_REGION,
}

DEPTH_STENCIL_VALUE :: struct {
	Depth:   f32,
	Stencil: u8,
}

CLEAR_VALUE :: struct {
	Format: dxgi.FORMAT,
	using _: struct #raw_union {
		Color:        [4]f32,
		DepthStencil: DEPTH_STENCIL_VALUE,
	},
}

RANGE :: struct {
	Begin: SIZE_T,
	End:   SIZE_T,
}

RANGE_UINT64 :: struct {
	Begin: u64,
	End:   u64,
}

SUBRESOURCE_RANGE_UINT64 :: struct {
	Subresource: u32,
	Range:       RANGE_UINT64,
}

SUBRESOURCE_INFO :: struct {
	Offset:     u64,
	RowPitch:   u32,
	DepthPitch: u32,
}

TILED_RESOURCE_COORDINATE :: struct {
	X:           u32,
	Y:           u32,
	Z:           u32,
	Subresource: u32,
}

TILE_REGION_SIZE :: struct {
	NumTiles: u32,
	UseBox:   BOOL,
	Width:    u32,
	Height:   u16,
	Depth:    u16,
}

TILE_RANGE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE              = 0x0,
	NULL              = 0x1,
	SKIP              = 0x2,
	REUSE_SINGLE_TILE = 0x4,
}

SUBRESOURCE_TILING :: struct {
	WidthInTiles:                    u32,
	HeightInTiles:                   u16,
	DepthInTiles:                    u16,
	StartTileIndexInOverallResource: u32,
}

TILE_SHAPE :: struct {
	WidthInTexels:  u32,
	HeightInTexels: u32,
	DepthInTexels:  u32,
}

PACKED_MIP_INFO :: struct {
	NumStandardMips:                 u8,
	NumPackedMips:                   u8,
	NumTilesForPackedMips:           u32,
	StartTileIndexInOverallResource: u32,
}

TILE_MAPPING_FLAGS :: enum u32 { // TODO: make bit_set
	NONE      = 0x0,
	NO_HAZARD = 0x1,
}

TILE_COPY_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                                     = 0x0,
	NO_HAZARD                                = 0x1,
	LINEAR_BUFFER_TO_SWIZZLED_TILED_RESOURCE = 0x2,
	SWIZZLED_TILED_RESOURCE_TO_LINEAR_BUFFER = 0x4,
}

RESOURCE_STATES :: enum i32 { // TODO: make bit_set
	COMMON                            = 0,
	VERTEX_AND_CONSTANT_BUFFER        = 1,
	INDEX_BUFFER                      = 2,
	RENDER_TARGET                     = 4,
	UNORDERED_ACCESS                  = 8,
	DEPTH_WRITE                       = 16,
	DEPTH_READ                        = 32,
	NON_PIXEL_SHADER_RESOURCE         = 64,
	PIXEL_SHADER_RESOURCE             = 128,
	STREAM_OUT                        = 256,
	INDIRECT_ARGUMENT                 = 512,
	COPY_DEST                         = 1024,
	COPY_SOURCE                       = 2048,
	RESOLVE_DEST                      = 4096,
	RESOLVE_SOURCE                    = 8192,
	RAYTRACING_ACCELERATION_STRUCTURE = 4194304,
	SHADING_RATE_SOURCE               = 16777216,
	GENERIC_READ                      = 2755,
	PRESENT                           = 0,
	PREDICATION                       = 512,
	VIDEO_DECODE_READ                 = 65536,
	VIDEO_DECODE_WRITE                = 131072,
	VIDEO_PROCESS_READ                = 262144,
	VIDEO_PROCESS_WRITE               = 524288,
	VIDEO_ENCODE_READ                 = 2097152,
	VIDEO_ENCODE_WRITE                = 8388608,
}

RESOURCE_BARRIER_TYPE :: enum i32 {
	TRANSITION = 0,
	ALIASING   = 1,
	UAV        = 2,
}

RESOURCE_TRANSITION_BARRIER :: struct {
	pResource:   ^IResource,
	Subresource: u32,
	StateBefore: RESOURCE_STATES,
	StateAfter:  RESOURCE_STATES,
}

RESOURCE_ALIASING_BARRIER :: struct {
	pResourceBefore: ^IResource,
	pResourceAfter:  ^IResource,
}

RESOURCE_UAV_BARRIER :: struct {
	pResource: ^IResource,
}

RESOURCE_BARRIER_FLAGS :: enum u32 { // TODO: make bit_set
	NONE       = 0x0,
	BEGIN_ONLY = 0x1,
	END_ONLY   = 0x2,
}

RESOURCE_BARRIER :: struct {
	Type:  RESOURCE_BARRIER_TYPE,
	Flags: RESOURCE_BARRIER_FLAGS,
	using _: struct #raw_union {
		Transition: RESOURCE_TRANSITION_BARRIER,
		Aliasing:   RESOURCE_ALIASING_BARRIER,
		UAV:        RESOURCE_UAV_BARRIER,
	},
}

SUBRESOURCE_FOOTPRINT :: struct {
	Format:   dxgi.FORMAT,
	Width:    u32,
	Height:   u32,
	Depth:    u32,
	RowPitch: u32,
}

PLACED_SUBRESOURCE_FOOTPRINT :: struct {
	Offset:    u64,
	Footprint: SUBRESOURCE_FOOTPRINT,
}

TEXTURE_COPY_TYPE :: enum i32 {
	SUBRESOURCE_INDEX = 0,
	PLACED_FOOTPRINT  = 1,
}

TEXTURE_COPY_LOCATION :: struct {
	pResource: ^IResource,
	Type:      TEXTURE_COPY_TYPE,
}

RESOLVE_MODE :: enum i32 {
	DECOMPRESS              = 0,
	MIN                     = 1,
	MAX                     = 2,
	AVERAGE                 = 3,
	ENCODE_SAMPLER_FEEDBACK = 4,
	DECODE_SAMPLER_FEEDBACK = 5,
}

SAMPLE_POSITION :: struct {
	X: i8,
	Y: i8,
}

VIEW_INSTANCE_LOCATION :: struct {
	ViewportArrayIndex:     u32,
	RenderTargetArrayIndex: u32,
}

VIEW_INSTANCING_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                         = 0x0,
	ENABLE_VIEW_INSTANCE_MASKING = 0x1,
}

VIEW_INSTANCING_DESC :: struct {
	ViewInstanceCount:      u32,
	pViewInstanceLocations: ^VIEW_INSTANCE_LOCATION,
	Flags:                  VIEW_INSTANCING_FLAGS,
}

SHADER_COMPONENT_MAPPING :: enum i32 {
	FROM_MEMORY_COMPONENT_0 = 0,
	FROM_MEMORY_COMPONENT_1 = 1,
	FROM_MEMORY_COMPONENT_2 = 2,
	FROM_MEMORY_COMPONENT_3 = 3,
	FORCE_VALUE_0           = 4,
	FORCE_VALUE_1           = 5,
}

BUFFER_SRV_FLAGS :: enum u32 { // TODO: make bit_set
	NONE = 0x0,
	RAW  = 0x1,
}

BUFFER_SRV :: struct {
	FirstElement:        u64,
	NumElements:         u32,
	StructureByteStride: u32,
	Flags:               BUFFER_SRV_FLAGS,
}

TEX1D_SRV :: struct {
	MostDetailedMip:     u32,
	MipLevels:           u32,
	ResourceMinLODClamp: f32,
}

TEX1D_ARRAY_SRV :: struct {
	MostDetailedMip:     u32,
	MipLevels:           u32,
	FirstArraySlice:     u32,
	ArraySize:           u32,
	ResourceMinLODClamp: f32,
}

TEX2D_SRV :: struct {
	MostDetailedMip:     u32,
	MipLevels:           u32,
	PlaneSlice:          u32,
	ResourceMinLODClamp: f32,
}

TEX2D_ARRAY_SRV :: struct {
	MostDetailedMip:     u32,
	MipLevels:           u32,
	FirstArraySlice:     u32,
	ArraySize:           u32,
	PlaneSlice:          u32,
	ResourceMinLODClamp: f32,
}

TEX3D_SRV :: struct {
	MostDetailedMip:     u32,
	MipLevels:           u32,
	ResourceMinLODClamp: f32,
}

TEXCUBE_SRV :: struct {
	MostDetailedMip:     u32,
	MipLevels:           u32,
	ResourceMinLODClamp: f32,
}

TEXCUBE_ARRAY_SRV :: struct {
	MostDetailedMip:     u32,
	MipLevels:           u32,
	First2DArrayFace:    u32,
	NumCubes:            u32,
	ResourceMinLODClamp: f32,
}

TEX2DMS_SRV :: struct {
	UnusedField_NothingToDefine: u32,
}

TEX2DMS_ARRAY_SRV :: struct {
	FirstArraySlice: u32,
	ArraySize:       u32,
}

RAYTRACING_ACCELERATION_STRUCTURE_SRV :: struct {
	Location: GPU_VIRTUAL_ADDRESS,
}

SHADER_RESOURCE_VIEW_DESC :: struct {
	Format:                  dxgi.FORMAT,
	ViewDimension:           SRV_DIMENSION,
	Shader4ComponentMapping: u32,
	using _: struct #raw_union {
		Buffer:                          BUFFER_SRV,
		Texture1D:                       TEX1D_SRV,
		Texture1DArray:                  TEX1D_ARRAY_SRV,
		Texture2D:                       TEX2D_SRV,
		Texture2DArray:                  TEX2D_ARRAY_SRV,
		Texture2DMS:                     TEX2DMS_SRV,
		Texture2DMSArray:                TEX2DMS_ARRAY_SRV,
		Texture3D:                       TEX3D_SRV,
		TextureCube:                     TEXCUBE_SRV,
		TextureCubeArray:                TEXCUBE_ARRAY_SRV,
		RaytracingAccelerationStructure: RAYTRACING_ACCELERATION_STRUCTURE_SRV,
	},
}

CONSTANT_BUFFER_VIEW_DESC :: struct {
	BufferLocation: GPU_VIRTUAL_ADDRESS,
	SizeInBytes:    u32,
}

FILTER :: enum i32 {
	MIN_MAG_MIP_POINT                          = 0,
	MIN_MAG_POINT_MIP_LINEAR                   = 1,
	MIN_POINT_MAG_LINEAR_MIP_POINT             = 4,
	MIN_POINT_MAG_MIP_LINEAR                   = 5,
	MIN_LINEAR_MAG_MIP_POINT                   = 16,
	MIN_LINEAR_MAG_POINT_MIP_LINEAR            = 17,
	MIN_MAG_LINEAR_MIP_POINT                   = 20,
	MIN_MAG_MIP_LINEAR                         = 21,
	ANISOTROPIC                                = 85,
	COMPARISON_MIN_MAG_MIP_POINT               = 128,
	COMPARISON_MIN_MAG_POINT_MIP_LINEAR        = 129,
	COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT  = 132,
	COMPARISON_MIN_POINT_MAG_MIP_LINEAR        = 133,
	COMPARISON_MIN_LINEAR_MAG_MIP_POINT        = 144,
	COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 145,
	COMPARISON_MIN_MAG_LINEAR_MIP_POINT        = 148,
	COMPARISON_MIN_MAG_MIP_LINEAR              = 149,
	COMPARISON_ANISOTROPIC                     = 213,
	MINIMUM_MIN_MAG_MIP_POINT                  = 256,
	MINIMUM_MIN_MAG_POINT_MIP_LINEAR           = 257,
	MINIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT     = 260,
	MINIMUM_MIN_POINT_MAG_MIP_LINEAR           = 261,
	MINIMUM_MIN_LINEAR_MAG_MIP_POINT           = 272,
	MINIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR    = 273,
	MINIMUM_MIN_MAG_LINEAR_MIP_POINT           = 276,
	MINIMUM_MIN_MAG_MIP_LINEAR                 = 277,
	MINIMUM_ANISOTROPIC                        = 341,
	MAXIMUM_MIN_MAG_MIP_POINT                  = 384,
	MAXIMUM_MIN_MAG_POINT_MIP_LINEAR           = 385,
	MAXIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT     = 388,
	MAXIMUM_MIN_POINT_MAG_MIP_LINEAR           = 389,
	MAXIMUM_MIN_LINEAR_MAG_MIP_POINT           = 400,
	MAXIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR    = 401,
	MAXIMUM_MIN_MAG_LINEAR_MIP_POINT           = 404,
	MAXIMUM_MIN_MAG_MIP_LINEAR                 = 405,
	MAXIMUM_ANISOTROPIC                        = 469,
}

FILTER_TYPE :: enum i32 {
	POINT  = 0,
	LINEAR = 1,
}

FILTER_REDUCTION_TYPE :: enum i32 {
	STANDARD   = 0,
	COMPARISON = 1,
	MINIMUM    = 2,
	MAXIMUM    = 3,
}

TEXTURE_ADDRESS_MODE :: enum i32 {
	WRAP        = 1,
	MIRROR      = 2,
	CLAMP       = 3,
	BORDER      = 4,
	MIRROR_ONCE = 5,
}

SAMPLER_DESC :: struct {
	Filter:         FILTER,
	AddressU:       TEXTURE_ADDRESS_MODE,
	AddressV:       TEXTURE_ADDRESS_MODE,
	AddressW:       TEXTURE_ADDRESS_MODE,
	MipLODBias:     f32,
	MaxAnisotropy:  u32,
	ComparisonFunc: COMPARISON_FUNC,
	BorderColor:    [4]f32,
	MinLOD:         f32,
	MaxLOD:         f32,
}

BUFFER_UAV_FLAGS :: enum u32 { // TODO: make bit_set
	NONE = 0x0,
	RAW  = 0x1,
}

BUFFER_UAV :: struct {
	FirstElement:         u64,
	NumElements:          u32,
	StructureByteStride:  u32,
	CounterOffsetInBytes: u64,
	Flags:                BUFFER_UAV_FLAGS,
}

TEX1D_UAV :: struct {
	MipSlice: u32,
}

TEX1D_ARRAY_UAV :: struct {
	MipSlice:        u32,
	FirstArraySlice: u32,
	ArraySize:       u32,
}

TEX2D_UAV :: struct {
	MipSlice:   u32,
	PlaneSlice: u32,
}

TEX2D_ARRAY_UAV :: struct {
	MipSlice:        u32,
	FirstArraySlice: u32,
	ArraySize:       u32,
	PlaneSlice:      u32,
}

TEX3D_UAV :: struct {
	MipSlice:    u32,
	FirstWSlice: u32,
	WSize:       u32,
}

UAV_DIMENSION :: enum i32 {
	UNKNOWN        = 0,
	BUFFER         = 1,
	TEXTURE1D      = 2,
	TEXTURE1DARRAY = 3,
	TEXTURE2D      = 4,
	TEXTURE2DARRAY = 5,
	TEXTURE3D      = 8,
}

UNORDERED_ACCESS_VIEW_DESC :: struct {
	Format:        dxgi.FORMAT,
	ViewDimension: UAV_DIMENSION,
	using _: struct #raw_union {
		Buffer:         BUFFER_UAV,
		Texture1D:      TEX1D_UAV,
		Texture1DArray: TEX1D_ARRAY_UAV,
		Texture2D:      TEX2D_UAV,
		Texture2DArray: TEX2D_ARRAY_UAV,
		Texture3D:      TEX3D_UAV,
	},
}

BUFFER_RTV :: struct {
	FirstElement: u64,
	NumElements:  u32,
}

TEX1D_RTV :: struct {
	MipSlice: u32,
}

TEX1D_ARRAY_RTV :: struct {
	MipSlice:        u32,
	FirstArraySlice: u32,
	ArraySize:       u32,
}

TEX2D_RTV :: struct {
	MipSlice:   u32,
	PlaneSlice: u32,
}

TEX2DMS_RTV :: struct {
	UnusedField_NothingToDefine: u32,
}

TEX2D_ARRAY_RTV :: struct {
	MipSlice:        u32,
	FirstArraySlice: u32,
	ArraySize:       u32,
	PlaneSlice:      u32,
}

TEX2DMS_ARRAY_RTV :: struct {
	FirstArraySlice: u32,
	ArraySize:       u32,
}

TEX3D_RTV :: struct {
	MipSlice:    u32,
	FirstWSlice: u32,
	WSize:       u32,
}

RTV_DIMENSION :: enum i32 {
	UNKNOWN          = 0,
	BUFFER           = 1,
	TEXTURE1D        = 2,
	TEXTURE1DARRAY   = 3,
	TEXTURE2D        = 4,
	TEXTURE2DARRAY   = 5,
	TEXTURE2DMS      = 6,
	TEXTURE2DMSARRAY = 7,
	TEXTURE3D        = 8,
}

RENDER_TARGET_VIEW_DESC :: struct {
	Format:        dxgi.FORMAT,
	ViewDimension: RTV_DIMENSION,
	using _: struct #raw_union {
		Buffer:           BUFFER_RTV,
		Texture1D:        TEX1D_RTV,
		Texture1DArray:   TEX1D_ARRAY_RTV,
		Texture2D:        TEX2D_RTV,
		Texture2DArray:   TEX2D_ARRAY_RTV,
		Texture2DMS:      TEX2DMS_RTV,
		Texture2DMSArray: TEX2DMS_ARRAY_RTV,
		Texture3D:        TEX3D_RTV,
	},
}

TEX1D_DSV :: struct {
	MipSlice: u32,
}

TEX1D_ARRAY_DSV :: struct {
	MipSlice:        u32,
	FirstArraySlice: u32,
	ArraySize:       u32,
}

TEX2D_DSV :: struct {
	MipSlice: u32,
}

TEX2D_ARRAY_DSV :: struct {
	MipSlice:        u32,
	FirstArraySlice: u32,
	ArraySize:       u32,
}

TEX2DMS_DSV :: struct {
	UnusedField_NothingToDefine: u32,
}

TEX2DMS_ARRAY_DSV :: struct {
	FirstArraySlice: u32,
	ArraySize:       u32,
}

DSV_FLAGS :: enum u32 { // TODO: make bit_set
	NONE              = 0x0,
	READ_ONLY_DEPTH   = 0x1,
	READ_ONLY_STENCIL = 0x2,
}

DSV_DIMENSION :: enum i32 {
	UNKNOWN          = 0,
	TEXTURE1D        = 1,
	TEXTURE1DARRAY   = 2,
	TEXTURE2D        = 3,
	TEXTURE2DARRAY   = 4,
	TEXTURE2DMS      = 5,
	TEXTURE2DMSARRAY = 6,
}

DEPTH_STENCIL_VIEW_DESC :: struct {
	Format:        dxgi.FORMAT,
	ViewDimension: DSV_DIMENSION,
	Flags:         DSV_FLAGS,
	using _: struct #raw_union {
		Texture1D:        TEX1D_DSV,
		Texture1DArray:   TEX1D_ARRAY_DSV,
		Texture2D:        TEX2D_DSV,
		Texture2DArray:   TEX2D_ARRAY_DSV,
		Texture2DMS:      TEX2DMS_DSV,
		Texture2DMSArray: TEX2DMS_ARRAY_DSV,
	},
}

CLEAR_FLAGS :: enum u32 { // TODO: make bit_set
	DEPTH   = 0x1,
	STENCIL = 0x2,
}

FENCE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                 = 0x0,
	SHARED               = 0x1,
	SHARED_CROSS_ADAPTER = 0x2,
	NON_MONITORED        = 0x4,
}

DESCRIPTOR_HEAP_TYPE :: enum i32 {
	CBV_SRV_UAV = 0,
	SAMPLER     = 1,
	RTV         = 2,
	DSV         = 3,
	NUM_TYPES   = 4,
}

DESCRIPTOR_HEAP_FLAGS :: enum u32 { // TODO: make bit_set
	NONE           = 0x0,
	SHADER_VISIBLE = 0x1,
}

DESCRIPTOR_HEAP_DESC :: struct {
	Type:           DESCRIPTOR_HEAP_TYPE,
	NumDescriptors: u32,
	Flags:          DESCRIPTOR_HEAP_FLAGS,
	NodeMask:       u32,
}

DESCRIPTOR_RANGE_TYPE :: enum i32 {
	SRV     = 0,
	UAV     = 1,
	CBV     = 2,
	SAMPLER = 3,
}

DESCRIPTOR_RANGE :: struct {
	RangeType:                         DESCRIPTOR_RANGE_TYPE,
	NumDescriptors:                    u32,
	BaseShaderRegister:                u32,
	RegisterSpace:                     u32,
	OffsetInDescriptorsFromTableStart: u32,
}

ROOT_DESCRIPTOR_TABLE :: struct {
	NumDescriptorRanges: u32,
	pDescriptorRanges:   ^DESCRIPTOR_RANGE,
}

ROOT_CONSTANTS :: struct {
	ShaderRegister: u32,
	RegisterSpace:  u32,
	Num32BitValues: u32,
}

ROOT_DESCRIPTOR :: struct {
	ShaderRegister: u32,
	RegisterSpace:  u32,
}

SHADER_VISIBILITY :: enum i32 {
	ALL           = 0,
	VERTEX        = 1,
	HULL          = 2,
	DOMAIN        = 3,
	GEOMETRY      = 4,
	PIXEL         = 5,
	AMPLIFICATION = 6,
	MESH          = 7,
}

ROOT_PARAMETER_TYPE :: enum i32 {
	DESCRIPTOR_TABLE = 0,
	_32BIT_CONSTANTS = 1,
	CBV              = 2,
	SRV              = 3,
	UAV              = 4,
}

ROOT_PARAMETER :: struct {
	ParameterType: ROOT_PARAMETER_TYPE,
	using _: struct #raw_union {
		DescriptorTable: ROOT_DESCRIPTOR_TABLE,
		Constants:       ROOT_CONSTANTS,
		Descriptor:      ROOT_DESCRIPTOR,
	},
	ShaderVisibility: SHADER_VISIBILITY,
}

ROOT_SIGNATURE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                                  = 0x0,
	ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT    = 0x1,
	DENY_VERTEX_SHADER_ROOT_ACCESS        = 0x2,
	DENY_HULL_SHADER_ROOT_ACCESS          = 0x4,
	DENY_DOMAIN_SHADER_ROOT_ACCESS        = 0x8,
	DENY_GEOMETRY_SHADER_ROOT_ACCESS      = 0x10,
	DENY_PIXEL_SHADER_ROOT_ACCESS         = 0x20,
	ALLOW_STREAM_OUTPUT                   = 0x40,
	LOCAL_ROOT_SIGNATURE                  = 0x80,
	DENY_AMPLIFICATION_SHADER_ROOT_ACCESS = 0x100,
	DENY_MESH_SHADER_ROOT_ACCESS          = 0x200,
}

STATIC_BORDER_COLOR :: enum i32 {
	TRANSPARENT_BLACK = 0,
	OPAQUE_BLACK      = 1,
	OPAQUE_WHITE      = 2,
}

STATIC_SAMPLER_DESC :: struct {
	Filter:           FILTER,
	AddressU:         TEXTURE_ADDRESS_MODE,
	AddressV:         TEXTURE_ADDRESS_MODE,
	AddressW:         TEXTURE_ADDRESS_MODE,
	MipLODBias:       f32,
	MaxAnisotropy:    u32,
	ComparisonFunc:   COMPARISON_FUNC,
	BorderColor:      STATIC_BORDER_COLOR,
	MinLOD:           f32,
	MaxLOD:           f32,
	ShaderRegister:   u32,
	RegisterSpace:    u32,
	ShaderVisibility: SHADER_VISIBILITY,
}

ROOT_SIGNATURE_DESC :: struct {
	NumParameters:     u32,
	pParameters:       ^ROOT_PARAMETER,
	NumStaticSamplers: u32,
	pStaticSamplers:   ^STATIC_SAMPLER_DESC,
	Flags:             ROOT_SIGNATURE_FLAGS,
}

DESCRIPTOR_RANGE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                                            = 0x0,
	DESCRIPTORS_VOLATILE                            = 0x1,
	DATA_VOLATILE                                   = 0x2,
	DATA_STATIC_WHILE_SET_AT_EXECUTE                = 0x4,
	DATA_STATIC                                     = 0x8,
	DESCRIPTORS_STATIC_KEEPING_BUFFER_BOUNDS_CHECKS = 0x10000,
}

DESCRIPTOR_RANGE1 :: struct {
	RangeType:                         DESCRIPTOR_RANGE_TYPE,
	NumDescriptors:                    u32,
	BaseShaderRegister:                u32,
	RegisterSpace:                     u32,
	Flags:                             DESCRIPTOR_RANGE_FLAGS,
	OffsetInDescriptorsFromTableStart: u32,
}

ROOT_DESCRIPTOR_TABLE1 :: struct {
	NumDescriptorRanges: u32,
	pDescriptorRanges:   ^DESCRIPTOR_RANGE1,
}

ROOT_DESCRIPTOR_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                             = 0x0,
	DATA_VOLATILE                    = 0x2,
	DATA_STATIC_WHILE_SET_AT_EXECUTE = 0x4,
	DATA_STATIC                      = 0x8,
}

ROOT_DESCRIPTOR1 :: struct {
	ShaderRegister: u32,
	RegisterSpace:  u32,
	Flags:          ROOT_DESCRIPTOR_FLAGS,
}

ROOT_PARAMETER1 :: struct {
	ParameterType:    ROOT_PARAMETER_TYPE,
	using _: struct #raw_union {
		DescriptorTable: ROOT_DESCRIPTOR_TABLE1,
		Constants:       ROOT_CONSTANTS,
		Descriptor:      ROOT_DESCRIPTOR1,
	},
	ShaderVisibility: SHADER_VISIBILITY,
}

ROOT_SIGNATURE_DESC1 :: struct {
	NumParameters:     u32,
	pParameters:       ^ROOT_PARAMETER1,
	NumStaticSamplers: u32,
	pStaticSamplers:   ^STATIC_SAMPLER_DESC,
	Flags:             ROOT_SIGNATURE_FLAGS,
}

VERSIONED_ROOT_SIGNATURE_DESC :: struct {
	Version: ROOT_SIGNATURE_VERSION,
	using _: struct #raw_union {
		Desc_1_0: ROOT_SIGNATURE_DESC,
		Desc_1_1: ROOT_SIGNATURE_DESC1,
	},
}


IRootSignatureDeserializer_UUID :: "34AB647B-3CC8-46AC-841B-C0965645C046"
IRootSignatureDeserializer :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12rootsignaturedeserializer_vtable: ^IRootSignatureDeserializer_VTable,
}
IRootSignatureDeserializer_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetRootSignatureDesc: proc "stdcall" (this: ^IRootSignatureDeserializer) -> ^ROOT_SIGNATURE_DESC,
}


IVersionedRootSignatureDeserializer_UUID :: "7F91CE67-090C-4BB7-B78E-ED8FF2E31DA0"
IVersionedRootSignatureDeserializer :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12versionedrootsignaturedeserializer_vtable: ^IVersionedRootSignatureDeserializer_VTable,
}
IVersionedRootSignatureDeserializer_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetRootSignatureDescAtVersion:   proc "stdcall" (this: ^IVersionedRootSignatureDeserializer, convertToVersion: ROOT_SIGNATURE_VERSION, ppDesc: ^^VERSIONED_ROOT_SIGNATURE_DESC) -> HRESULT,
	GetUnconvertedRootSignatureDesc: proc "stdcall" (this: ^IVersionedRootSignatureDeserializer) -> ^VERSIONED_ROOT_SIGNATURE_DESC,
}

PFN_SERIALIZE_ROOT_SIGNATURE                     :: #type proc "c" (a0: ^ROOT_SIGNATURE_DESC, a1: ROOT_SIGNATURE_VERSION, a2: ^^IBlob, a3: ^^IBlob) -> HRESULT
PFN_CREATE_ROOT_SIGNATURE_DESERIALIZER           :: #type proc "c" (a0: rawptr, a1: SIZE_T, a2: ^IID, a3: ^rawptr) -> HRESULT
PFN_SERIALIZE_VERSIONED_ROOT_SIGNATURE           :: #type proc "c" (a0: ^VERSIONED_ROOT_SIGNATURE_DESC, a1: ^^IBlob, a2: ^^IBlob) -> HRESULT
PFN_CREATE_VERSIONED_ROOT_SIGNATURE_DESERIALIZER :: #type proc "c" (a0: rawptr, a1: SIZE_T, a2: ^IID, a3: ^rawptr) -> HRESULT


CPU_DESCRIPTOR_HANDLE :: struct {
	ptr: SIZE_T,
}

GPU_DESCRIPTOR_HANDLE :: struct {
	ptr: u64,
}

DISCARD_REGION :: struct {
	NumRects:         u32,
	pRects:           ^RECT,
	FirstSubresource: u32,
	NumSubresources:  u32,
}

QUERY_HEAP_TYPE :: enum i32 {
	OCCLUSION               = 0,
	TIMESTAMP               = 1,
	PIPELINE_STATISTICS     = 2,
	SO_STATISTICS           = 3,
	VIDEO_DECODE_STATISTICS = 4,
	COPY_QUEUE_TIMESTAMP    = 5,
}

QUERY_HEAP_DESC :: struct {
	Type:     QUERY_HEAP_TYPE,
	Count:    u32,
	NodeMask: u32,
}

QUERY_TYPE :: enum i32 {
	OCCLUSION               = 0,
	BINARY_OCCLUSION        = 1,
	TIMESTAMP               = 2,
	PIPELINE_STATISTICS     = 3,
	SO_STATISTICS_STREAM0   = 4,
	SO_STATISTICS_STREAM1   = 5,
	SO_STATISTICS_STREAM2   = 6,
	SO_STATISTICS_STREAM3   = 7,
	VIDEO_DECODE_STATISTICS = 8,
}

PREDICATION_OP :: enum i32 {
	EQUAL_ZERO     = 0,
	NOT_EQUAL_ZERO = 1,
}

QUERY_DATA_PIPELINE_STATISTICS :: struct {
	IAVertices:    u64,
	IAPrimitives:  u64,
	VSInvocations: u64,
	GSInvocations: u64,
	GSPrimitives:  u64,
	CInvocations:  u64,
	CPrimitives:   u64,
	PSInvocations: u64,
	HSInvocations: u64,
	DSInvocations: u64,
	CSInvocations: u64,
}

QUERY_DATA_SO_STATISTICS :: struct {
	NumPrimitivesWritten:    u64,
	PrimitivesStorageNeeded: u64,
}

STREAM_OUTPUT_BUFFER_VIEW :: struct {
	BufferLocation:           GPU_VIRTUAL_ADDRESS,
	SizeInBytes:              u64,
	BufferFilledSizeLocation: GPU_VIRTUAL_ADDRESS,
}

DRAW_ARGUMENTS :: struct {
	VertexCountPerInstance: u32,
	InstanceCount:          u32,
	StartVertexLocation:    u32,
	StartInstanceLocation:  u32,
}

DRAW_INDEXED_ARGUMENTS :: struct {
	IndexCountPerInstance: u32,
	InstanceCount:         u32,
	StartIndexLocation:    u32,
	BaseVertexLocation:    i32,
	StartInstanceLocation: u32,
}

DISPATCH_ARGUMENTS :: struct {
	ThreadGroupCountX: u32,
	ThreadGroupCountY: u32,
	ThreadGroupCountZ: u32,
}

VERTEX_BUFFER_VIEW :: struct {
	BufferLocation: GPU_VIRTUAL_ADDRESS,
	SizeInBytes:    u32,
	StrideInBytes:  u32,
}

INDEX_BUFFER_VIEW :: struct {
	BufferLocation: GPU_VIRTUAL_ADDRESS,
	SizeInBytes:    u32,
	Format:         dxgi.FORMAT,
}

INDIRECT_ARGUMENT_TYPE :: enum i32 {
	DRAW                  = 0,
	DRAW_INDEXED          = 1,
	DISPATCH              = 2,
	VERTEX_BUFFER_VIEW    = 3,
	INDEX_BUFFER_VIEW     = 4,
	CONSTANT              = 5,
	CONSTANT_BUFFER_VIEW  = 6,
	SHADER_RESOURCE_VIEW  = 7,
	UNORDERED_ACCESS_VIEW = 8,
	DISPATCH_RAYS         = 9,
	DISPATCH_MESH         = 10,
}

INDIRECT_ARGUMENT_DESC :: struct {
	Type: INDIRECT_ARGUMENT_TYPE,
	using _: struct #raw_union {
		VertexBuffer: struct {
			Slot: u32,
		},
		Constant: struct {
			RootParameterIndex:      u32,
			DestOffsetIn32BitValues: u32,
			Num32BitValuesToSet:     u32,
		},
		ConstantBufferView: struct {
			RootParameterIndex: u32,
		},
		ShaderResourceView: struct {
			RootParameterIndex: u32,
		},
		UnorderedAccessView: struct {
			RootParameterIndex: u32,
		},
	},
}

COMMAND_SIGNATURE_DESC :: struct {
	ByteStride:       u32,
	NumArgumentDescs: u32,
	pArgumentDescs:   ^INDIRECT_ARGUMENT_DESC,
	NodeMask:         u32,
}


IPageable_UUID :: "63ee58fb-1268-4835-86da-f008ce62f0d6"
IPageable :: struct {
	using id3d12devicechild: IDeviceChild,
}


IHeap_UUID :: "6b3b2502-6e51-45b3-90ee-9884265e8df3"
IHeap :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12heap_vtable: ^IHeap_VTable,
}
IHeap_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	GetDesc: proc "stdcall" (this: ^IHeap) -> HEAP_DESC,
}


IResource_UUID :: "696442be-a72e-4059-bc79-5b5c98040fad"
IResource :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12resource_vtable: ^IResource_VTable,
}
IResource_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	Map:                  proc "stdcall" (this: ^IResource, Subresource: u32, pReadRange: ^RANGE, ppData: ^rawptr) -> HRESULT,
	Unmap:                proc "stdcall" (this: ^IResource, Subresource: u32, pWrittenRange: ^RANGE),
	GetDesc:              proc "stdcall" (this: ^IResource) -> RESOURCE_DESC,
	GetGPUVirtualAddress: proc "stdcall" (this: ^IResource) -> GPU_VIRTUAL_ADDRESS,
	WriteToSubresource:   proc "stdcall" (this: ^IResource, DstSubresource: u32, pDstBox: ^BOX, pSrcData: rawptr, SrcRowPitch: u32, SrcDepthPitch: u32) -> HRESULT,
	ReadFromSubresource:  proc "stdcall" (this: ^IResource, pDstData: rawptr, DstRowPitch: u32, DstDepthPitch: u32, SrcSubresource: u32, pSrcBox: ^BOX) -> HRESULT,
	GetHeapProperties:    proc "stdcall" (this: ^IResource, pHeapProperties: ^HEAP_PROPERTIES, pHeapFlags: ^HEAP_FLAGS) -> HRESULT,
}


ICommandAllocator_UUID :: "6102dee4-af59-4b09-b999-b44d73f09b24"
ICommandAllocator :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12commandallocator_vtable: ^ICommandAllocator_VTable,
}
ICommandAllocator_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	Reset: proc "stdcall" (this: ^ICommandAllocator) -> HRESULT,
}


IFence_UUID :: "0a753dcf-c4d8-4b91-adf6-be5a60d95a76"
IFence :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12fence_vtable: ^IFence_VTable,
}
IFence_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	GetCompletedValue:    proc "stdcall" (this: ^IFence) -> u64,
	SetEventOnCompletion: proc "stdcall" (this: ^IFence, Value: u64, hEvent: HANDLE) -> HRESULT,
	Signal:               proc "stdcall" (this: ^IFence, Value: u64) -> HRESULT,
}


IFence1_UUID :: "433685fe-e22b-4ca0-a8db-b5b4f4dd0e4a"
IFence1 :: struct #raw_union {
	#subtype id3d12fence: IFence,
	using id3d12fence1_vtable: ^IFence1_VTable,
}
IFence1_VTable :: struct {
	#subtype id3d12fence_vtable: IFence_VTable,
	GetCreationFlags: proc "stdcall" (this: ^IFence1) -> FENCE_FLAGS,
}


IPipelineState_UUID :: "765a30f3-f624-4c6f-a828-ace948622445"
IPipelineState :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12pipelinestate_vtable: ^IPipelineState_VTable,
}
IPipelineState_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	GetCachedBlob: proc "stdcall" (this: ^IPipelineState, ppBlob: ^^IBlob) -> HRESULT,
}


IDescriptorHeap_UUID :: "8efb471d-616c-4f49-90f7-127bb763fa51"
IDescriptorHeap :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12descriptorheap_vtable: ^IDescriptorHeap_VTable,
}
IDescriptorHeap_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	GetDesc:                            proc "stdcall" (this: ^IDescriptorHeap) -> DESCRIPTOR_HEAP_DESC,
	GetCPUDescriptorHandleForHeapStart: proc "stdcall" (this: ^IDescriptorHeap) -> CPU_DESCRIPTOR_HANDLE,
	GetGPUDescriptorHandleForHeapStart: proc "stdcall" (this: ^IDescriptorHeap) -> GPU_DESCRIPTOR_HANDLE,
}


IQueryHeap_UUID :: "0d9658ae-ed45-469e-a61d-970ec583cab4"
IQueryHeap :: struct {
	#subtype id3d12pageable: IPageable,
}


ICommandSignature_UUID :: "c36a797c-ec80-4f0a-8985-a7b2475082d1"
ICommandSignature :: struct {
	#subtype id3d12pageable: IPageable,
}


ICommandList_UUID :: "7116d91c-e7e4-47ce-b8c6-ec8168f437e5"
ICommandList :: struct #raw_union {
	#subtype id3d12devicechild: IDeviceChild,
	using id3d12commandlist_vtable: ^ICommandList_VTable,
}
ICommandList_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	GetType: proc "stdcall" (this: ^ICommandList) -> COMMAND_LIST_TYPE,
}


IGraphicsCommandList_UUID :: "5b160d0f-ac1b-4185-8ba8-b3ae42a5a455"
IGraphicsCommandList :: struct #raw_union {
	#subtype id3d12commandlist: ICommandList,
	using id3d12graphicscommandlist_vtable: ^IGraphicsCommandList_VTable,
}
IGraphicsCommandList_VTable :: struct {
	using id3d12commandlist_vtable: ICommandList_VTable,
	Close:                              proc "stdcall" (this: ^IGraphicsCommandList) -> HRESULT,
	Reset:                              proc "stdcall" (this: ^IGraphicsCommandList, pAllocator: ^ICommandAllocator, pInitialState: ^IPipelineState) -> HRESULT,
	ClearState:                         proc "stdcall" (this: ^IGraphicsCommandList, pPipelineState: ^IPipelineState),
	DrawInstanced:                      proc "stdcall" (this: ^IGraphicsCommandList, VertexCountPerInstance: u32, InstanceCount: u32, StartVertexLocation: u32, StartInstanceLocation: u32),
	DrawIndexedInstanced:               proc "stdcall" (this: ^IGraphicsCommandList, IndexCountPerInstance: u32, InstanceCount: u32, StartIndexLocation: u32, BaseVertexLocation: i32, StartInstanceLocation: u32),
	Dispatch:                           proc "stdcall" (this: ^IGraphicsCommandList, ThreadGroupCountX: u32, ThreadGroupCountY: u32, ThreadGroupCountZ: u32),
	CopyBufferRegion:                   proc "stdcall" (this: ^IGraphicsCommandList, pDstBuffer: ^IResource, DstOffset: u64, pSrcBuffer: ^IResource, SrcOffset: u64, NumBytes: u64),
	CopyTextureRegion:                  proc "stdcall" (this: ^IGraphicsCommandList, pDst: ^TEXTURE_COPY_LOCATION, DstX: u32, DstY: u32, DstZ: u32, pSrc: ^TEXTURE_COPY_LOCATION, pSrcBox: ^BOX),
	CopyResource:                       proc "stdcall" (this: ^IGraphicsCommandList, pDstResource: ^IResource, pSrcResource: ^IResource),
	CopyTiles:                          proc "stdcall" (this: ^IGraphicsCommandList, pTiledResource: ^IResource, pTileRegionStartCoordinate: ^TILED_RESOURCE_COORDINATE, pTileRegionSize: ^TILE_REGION_SIZE, pBuffer: ^IResource, BufferStartOffsetInBytes: u64, Flags: TILE_COPY_FLAGS),
	ResolveSubresource:                 proc "stdcall" (this: ^IGraphicsCommandList, pDstResource: ^IResource, DstSubresource: u32, pSrcResource: ^IResource, SrcSubresource: u32, Format: dxgi.FORMAT),
	IASetPrimitiveTopology:             proc "stdcall" (this: ^IGraphicsCommandList, PrimitiveTopology: PRIMITIVE_TOPOLOGY),
	RSSetViewports:                     proc "stdcall" (this: ^IGraphicsCommandList, NumViewports: u32, pViewports: ^VIEWPORT),
	RSSetScissorRects:                  proc "stdcall" (this: ^IGraphicsCommandList, NumRects: u32, pRects: ^RECT),
	OMSetBlendFactor:                   proc "stdcall" (this: ^IGraphicsCommandList, BlendFactor: ^[4]f32),
	OMSetStencilRef:                    proc "stdcall" (this: ^IGraphicsCommandList, StencilRef: u32),
	SetPipelineState:                   proc "stdcall" (this: ^IGraphicsCommandList, pPipelineState: ^IPipelineState),
	ResourceBarrier:                    proc "stdcall" (this: ^IGraphicsCommandList, NumBarriers: u32, pBarriers: ^RESOURCE_BARRIER),
	ExecuteBundle:                      proc "stdcall" (this: ^IGraphicsCommandList, pCommandList: ^IGraphicsCommandList),
	SetDescriptorHeaps:                 proc "stdcall" (this: ^IGraphicsCommandList, NumDescriptorHeaps: u32, ppDescriptorHeaps: ^^IDescriptorHeap),
	SetComputeRootSignature:            proc "stdcall" (this: ^IGraphicsCommandList, pRootSignature: ^IRootSignature),
	SetGraphicsRootSignature:           proc "stdcall" (this: ^IGraphicsCommandList, pRootSignature: ^IRootSignature),
	SetComputeRootDescriptorTable:      proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BaseDescriptor: GPU_DESCRIPTOR_HANDLE),
	SetGraphicsRootDescriptorTable:     proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BaseDescriptor: GPU_DESCRIPTOR_HANDLE),
	SetComputeRoot32BitConstant:        proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, SrcData: u32, DestOffsetIn32BitValues: u32),
	SetGraphicsRoot32BitConstant:       proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, SrcData: u32, DestOffsetIn32BitValues: u32),
	SetComputeRoot32BitConstants:       proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, Num32BitValuesToSet: u32, pSrcData: rawptr, DestOffsetIn32BitValues: u32),
	SetGraphicsRoot32BitConstants:      proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, Num32BitValuesToSet: u32, pSrcData: rawptr, DestOffsetIn32BitValues: u32),
	SetComputeRootConstantBufferView:   proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BufferLocation: GPU_VIRTUAL_ADDRESS),
	SetGraphicsRootConstantBufferView:  proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BufferLocation: GPU_VIRTUAL_ADDRESS),
	SetComputeRootShaderResourceView:   proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BufferLocation: GPU_VIRTUAL_ADDRESS),
	SetGraphicsRootShaderResourceView:  proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BufferLocation: GPU_VIRTUAL_ADDRESS),
	SetComputeRootUnorderedAccessView:  proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BufferLocation: GPU_VIRTUAL_ADDRESS),
	SetGraphicsRootUnorderedAccessView: proc "stdcall" (this: ^IGraphicsCommandList, RootParameterIndex: u32, BufferLocation: GPU_VIRTUAL_ADDRESS),
	IASetIndexBuffer:                   proc "stdcall" (this: ^IGraphicsCommandList, pView: ^INDEX_BUFFER_VIEW),
	IASetVertexBuffers:                 proc "stdcall" (this: ^IGraphicsCommandList, StartSlot: u32, NumViews: u32, pViews: ^VERTEX_BUFFER_VIEW),
	SOSetTargets:                       proc "stdcall" (this: ^IGraphicsCommandList, StartSlot: u32, NumViews: u32, pViews: ^STREAM_OUTPUT_BUFFER_VIEW),
	OMSetRenderTargets:                 proc "stdcall" (this: ^IGraphicsCommandList, NumRenderTargetDescriptors: u32, pRenderTargetDescriptors: ^CPU_DESCRIPTOR_HANDLE, RTsSingleHandleToDescriptorRange: BOOL, pDepthStencilDescriptor: ^CPU_DESCRIPTOR_HANDLE),
	ClearDepthStencilView:              proc "stdcall" (this: ^IGraphicsCommandList, DepthStencilView: CPU_DESCRIPTOR_HANDLE, ClearFlags: CLEAR_FLAGS, Depth: f32, Stencil: u8, NumRects: u32, pRects: ^RECT),
	ClearRenderTargetView:              proc "stdcall" (this: ^IGraphicsCommandList, RenderTargetView: CPU_DESCRIPTOR_HANDLE, ColorRGBA: ^[4]f32, NumRects: u32, pRects: ^RECT),
	ClearUnorderedAccessViewUint:       proc "stdcall" (this: ^IGraphicsCommandList, ViewGPUHandleInCurrentHeap: GPU_DESCRIPTOR_HANDLE, ViewCPUHandle: CPU_DESCRIPTOR_HANDLE, pResource: ^IResource, Values: ^[4]u32, NumRects: u32, pRects: ^RECT),
	ClearUnorderedAccessViewFloat:      proc "stdcall" (this: ^IGraphicsCommandList, ViewGPUHandleInCurrentHeap: GPU_DESCRIPTOR_HANDLE, ViewCPUHandle: CPU_DESCRIPTOR_HANDLE, pResource: ^IResource, Values: ^[4]f32, NumRects: u32, pRects: ^RECT),
	DiscardResource:                    proc "stdcall" (this: ^IGraphicsCommandList, pResource: ^IResource, pRegion: ^DISCARD_REGION),
	BeginQuery:                         proc "stdcall" (this: ^IGraphicsCommandList, pQueryHeap: ^IQueryHeap, Type: QUERY_TYPE, Index: u32),
	EndQuery:                           proc "stdcall" (this: ^IGraphicsCommandList, pQueryHeap: ^IQueryHeap, Type: QUERY_TYPE, Index: u32),
	ResolveQueryData:                   proc "stdcall" (this: ^IGraphicsCommandList, pQueryHeap: ^IQueryHeap, Type: QUERY_TYPE, StartIndex: u32, NumQueries: u32, pDestinationBuffer: ^IResource, AlignedDestinationBufferOffset: u64),
	SetPredication:                     proc "stdcall" (this: ^IGraphicsCommandList, pBuffer: ^IResource, AlignedBufferOffset: u64, Operation: PREDICATION_OP),
	SetMarker:                          proc "stdcall" (this: ^IGraphicsCommandList, Metadata: u32, pData: rawptr, Size: u32),
	BeginEvent:                         proc "stdcall" (this: ^IGraphicsCommandList, Metadata: u32, pData: rawptr, Size: u32),
	EndEvent:                           proc "stdcall" (this: ^IGraphicsCommandList),
	ExecuteIndirect:                    proc "stdcall" (this: ^IGraphicsCommandList, pCommandSignature: ^ICommandSignature, MaxCommandCount: u32, pArgumentBuffer: ^IResource, ArgumentBufferOffset: u64, pCountBuffer: ^IResource, CountBufferOffset: u64),
}


IGraphicsCommandList1_UUID :: "553103fb-1fe7-4557-bb38-946d7d0e7ca7"
IGraphicsCommandList1 :: struct #raw_union {
	#subtype id3d12graphicscommandlist: IGraphicsCommandList,
	using id3d12graphicscommandlist1_vtable: ^IGraphicsCommandList1_VTable,
}
IGraphicsCommandList1_VTable :: struct {
	using id3d12graphicscommandlist_vtable: IGraphicsCommandList_VTable,
	AtomicCopyBufferUINT:     proc "stdcall" (this: ^IGraphicsCommandList1, pDstBuffer: ^IResource, DstOffset: u64, pSrcBuffer: ^IResource, SrcOffset: u64, Dependencies: u32, ppDependentResources: ^^IResource, pDependentSubresourceRanges: ^SUBRESOURCE_RANGE_UINT64),
	AtomicCopyBufferUINT64:   proc "stdcall" (this: ^IGraphicsCommandList1, pDstBuffer: ^IResource, DstOffset: u64, pSrcBuffer: ^IResource, SrcOffset: u64, Dependencies: u32, ppDependentResources: ^^IResource, pDependentSubresourceRanges: ^SUBRESOURCE_RANGE_UINT64),
	OMSetDepthBounds:         proc "stdcall" (this: ^IGraphicsCommandList1, Min: f32, Max: f32),
	SetSamplePositions:       proc "stdcall" (this: ^IGraphicsCommandList1, NumSamplesPerPixel: u32, NumPixels: u32, pSamplePositions: ^SAMPLE_POSITION),
	ResolveSubresourceRegion: proc "stdcall" (this: ^IGraphicsCommandList1, pDstResource: ^IResource, DstSubresource: u32, DstX: u32, DstY: u32, pSrcResource: ^IResource, SrcSubresource: u32, pSrcRect: ^RECT, Format: dxgi.FORMAT, ResolveMode: RESOLVE_MODE),
	SetViewInstanceMask:      proc "stdcall" (this: ^IGraphicsCommandList1, Mask: u32),
}

WRITEBUFFERIMMEDIATE_PARAMETER :: struct {
	Dest:  GPU_VIRTUAL_ADDRESS,
	Value: u32,
}

WRITEBUFFERIMMEDIATE_MODE :: enum i32 {
	DEFAULT    = 0,
	MARKER_IN  = 1,
	MARKER_OUT = 2,
}


IGraphicsCommandList2_UUID :: "38C3E585-FF17-412C-9150-4FC6F9D72A28"
IGraphicsCommandList2 :: struct #raw_union {
	#subtype id3d12graphicscommandlist1: IGraphicsCommandList1,
	using id3d12graphicscommandlist2_vtable: ^IGraphicsCommandList2_VTable,
}
IGraphicsCommandList2_VTable :: struct {
	using id3d12graphicscommandlist1_vtable: IGraphicsCommandList1_VTable,
	WriteBufferImmediate: proc "stdcall" (this: ^IGraphicsCommandList2, Count: u32, pParams: ^WRITEBUFFERIMMEDIATE_PARAMETER, pModes: ^WRITEBUFFERIMMEDIATE_MODE),
}


ICommandQueue_UUID :: "0ec870a6-5d7e-4c22-8cfc-5baae07616ed"
ICommandQueue :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12commandqueue_vtable: ^ICommandQueue_VTable,
}
ICommandQueue_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	UpdateTileMappings:    proc "stdcall" (this: ^ICommandQueue, pResource: ^IResource, NumResourceRegions: u32, pResourceRegionStartCoordinates: ^TILED_RESOURCE_COORDINATE, pResourceRegionSizes: ^TILE_REGION_SIZE, pHeap: ^IHeap, NumRanges: u32, pRangeFlags: ^TILE_RANGE_FLAGS, pHeapRangeStartOffsets: ^u32, pRangeTileCounts: ^u32, Flags: TILE_MAPPING_FLAGS),
	CopyTileMappings:      proc "stdcall" (this: ^ICommandQueue, pDstResource: ^IResource, pDstRegionStartCoordinate: ^TILED_RESOURCE_COORDINATE, pSrcResource: ^IResource, pSrcRegionStartCoordinate: ^TILED_RESOURCE_COORDINATE, pRegionSize: ^TILE_REGION_SIZE, Flags: TILE_MAPPING_FLAGS),
	ExecuteCommandLists:   proc "stdcall" (this: ^ICommandQueue, NumCommandLists: u32, ppCommandLists: ^^ICommandList),
	SetMarker:             proc "stdcall" (this: ^ICommandQueue, Metadata: u32, pData: rawptr, Size: u32),
	BeginEvent:            proc "stdcall" (this: ^ICommandQueue, Metadata: u32, pData: rawptr, Size: u32),
	EndEvent:              proc "stdcall" (this: ^ICommandQueue),
	Signal:                proc "stdcall" (this: ^ICommandQueue, pFence: ^IFence, Value: u64) -> HRESULT,
	Wait:                  proc "stdcall" (this: ^ICommandQueue, pFence: ^IFence, Value: u64) -> HRESULT,
	GetTimestampFrequency: proc "stdcall" (this: ^ICommandQueue, pFrequency: ^u64) -> HRESULT,
	GetClockCalibration:   proc "stdcall" (this: ^ICommandQueue, pGpuTimestamp: ^u64, pCpuTimestamp: ^u64) -> HRESULT,
	GetDesc:               proc "stdcall" (this: ^ICommandQueue) -> COMMAND_QUEUE_DESC,
}


IDevice_UUID :: "189819f1-1db6-4b57-be54-1821339b85f7"
IDevice :: struct #raw_union {
	#subtype id3d12object: IObject,
	using id3d12device_vtable: ^IDevice_VTable,
}
IDevice_VTable :: struct {
	using id3d12object_vtable: IObject_VTable,
	GetNodeCount:                     proc "stdcall" (this: ^IDevice) -> u32,
	CreateCommandQueue:               proc "stdcall" (this: ^IDevice, pDesc: ^COMMAND_QUEUE_DESC, riid: ^IID, ppCommandQueue: ^rawptr) -> HRESULT,
	CreateCommandAllocator:           proc "stdcall" (this: ^IDevice, type: COMMAND_LIST_TYPE, riid: ^IID, ppCommandAllocator: ^rawptr) -> HRESULT,
	CreateGraphicsPipelineState:      proc "stdcall" (this: ^IDevice, pDesc: ^GRAPHICS_PIPELINE_STATE_DESC, riid: ^IID, ppPipelineState: ^rawptr) -> HRESULT,
	CreateComputePipelineState:       proc "stdcall" (this: ^IDevice, pDesc: ^COMPUTE_PIPELINE_STATE_DESC, riid: ^IID, ppPipelineState: ^rawptr) -> HRESULT,
	CreateCommandList:                proc "stdcall" (this: ^IDevice, nodeMask: u32, type: COMMAND_LIST_TYPE, pCommandAllocator: ^ICommandAllocator, pInitialState: ^IPipelineState, riid: ^IID, ppCommandList: ^rawptr) -> HRESULT,
	CheckFeatureSupport:              proc "stdcall" (this: ^IDevice, Feature: FEATURE, pFeatureSupportData: rawptr, FeatureSupportDataSize: u32) -> HRESULT,
	CreateDescriptorHeap:             proc "stdcall" (this: ^IDevice, pDescriptorHeapDesc: ^DESCRIPTOR_HEAP_DESC, riid: ^IID, ppvHeap: ^rawptr) -> HRESULT,
	GetDescriptorHandleIncrementSize: proc "stdcall" (this: ^IDevice, DescriptorHeapType: DESCRIPTOR_HEAP_TYPE) -> u32,
	CreateRootSignature:              proc "stdcall" (this: ^IDevice, nodeMask: u32, pBlobWithRootSignature: rawptr, blobLengthInBytes: SIZE_T, riid: ^IID, ppvRootSignature: ^rawptr) -> HRESULT,
	CreateConstantBufferView:         proc "stdcall" (this: ^IDevice, pDesc: ^CONSTANT_BUFFER_VIEW_DESC, DestDescriptor: CPU_DESCRIPTOR_HANDLE),
	CreateShaderResourceView:         proc "stdcall" (this: ^IDevice, pResource: ^IResource, pDesc: ^SHADER_RESOURCE_VIEW_DESC, DestDescriptor: CPU_DESCRIPTOR_HANDLE),
	CreateUnorderedAccessView:        proc "stdcall" (this: ^IDevice, pResource: ^IResource, pCounterResource: ^IResource, pDesc: ^UNORDERED_ACCESS_VIEW_DESC, DestDescriptor: CPU_DESCRIPTOR_HANDLE),
	CreateRenderTargetView:           proc "stdcall" (this: ^IDevice, pResource: ^IResource, pDesc: ^RENDER_TARGET_VIEW_DESC, DestDescriptor: CPU_DESCRIPTOR_HANDLE),
	CreateDepthStencilView:           proc "stdcall" (this: ^IDevice, pResource: ^IResource, pDesc: ^DEPTH_STENCIL_VIEW_DESC, DestDescriptor: CPU_DESCRIPTOR_HANDLE),
	CreateSampler:                    proc "stdcall" (this: ^IDevice, pDesc: ^SAMPLER_DESC, DestDescriptor: CPU_DESCRIPTOR_HANDLE),
	CopyDescriptors:                  proc "stdcall" (this: ^IDevice, NumDestDescriptorRanges: u32, pDestDescriptorRangeStarts: ^CPU_DESCRIPTOR_HANDLE, pDestDescriptorRangeSizes: ^u32, NumSrcDescriptorRanges: u32, pSrcDescriptorRangeStarts: ^CPU_DESCRIPTOR_HANDLE, pSrcDescriptorRangeSizes: ^u32, DescriptorHeapsType: DESCRIPTOR_HEAP_TYPE),
	CopyDescriptorsSimple:            proc "stdcall" (this: ^IDevice, NumDescriptors: u32, DestDescriptorRangeStart: CPU_DESCRIPTOR_HANDLE, SrcDescriptorRangeStart: CPU_DESCRIPTOR_HANDLE, DescriptorHeapsType: DESCRIPTOR_HEAP_TYPE),
	GetResourceAllocationInfo:        proc "stdcall" (this: ^IDevice, visibleMask: u32, numResourceDescs: u32, pResourceDescs: ^RESOURCE_DESC) -> RESOURCE_ALLOCATION_INFO,
	GetCustomHeapProperties:          proc "stdcall" (this: ^IDevice, nodeMask: u32, heapType: HEAP_TYPE) -> HEAP_PROPERTIES,
	CreateCommittedResource:          proc "stdcall" (this: ^IDevice, pHeapProperties: ^HEAP_PROPERTIES, HeapFlags: HEAP_FLAGS, pDesc: ^RESOURCE_DESC, InitialResourceState: RESOURCE_STATES, pOptimizedClearValue: ^CLEAR_VALUE, riidResource: ^IID, ppvResource: ^rawptr) -> HRESULT,
	CreateHeap:                       proc "stdcall" (this: ^IDevice, pDesc: ^HEAP_DESC, riid: ^IID, ppvHeap: ^rawptr) -> HRESULT,
	CreatePlacedResource:             proc "stdcall" (this: ^IDevice, pHeap: ^IHeap, HeapOffset: u64, pDesc: ^RESOURCE_DESC, InitialState: RESOURCE_STATES, pOptimizedClearValue: ^CLEAR_VALUE, riid: ^IID, ppvResource: ^rawptr) -> HRESULT,
	CreateReservedResource:           proc "stdcall" (this: ^IDevice, pDesc: ^RESOURCE_DESC, InitialState: RESOURCE_STATES, pOptimizedClearValue: ^CLEAR_VALUE, riid: ^IID, ppvResource: ^rawptr) -> HRESULT,
	CreateSharedHandle:               proc "stdcall" (this: ^IDevice, pObject: ^IDeviceChild, pAttributes: ^win32.SECURITY_ATTRIBUTES, Access: u32, Name: [^]u16, pHandle: ^HANDLE) -> HRESULT,
	OpenSharedHandle:                 proc "stdcall" (this: ^IDevice, NTHandle: HANDLE, riid: ^IID, ppvObj: ^rawptr) -> HRESULT,
	OpenSharedHandleByName:           proc "stdcall" (this: ^IDevice, Name: [^]u16, Access: u32, pNTHandle: ^HANDLE) -> HRESULT,
	MakeResident:                     proc "stdcall" (this: ^IDevice, NumObjects: u32, ppObjects: ^^IPageable) -> HRESULT,
	Evict:                            proc "stdcall" (this: ^IDevice, NumObjects: u32, ppObjects: ^^IPageable) -> HRESULT,
	CreateFence:                      proc "stdcall" (this: ^IDevice, InitialValue: u64, Flags: FENCE_FLAGS, riid: ^IID, ppFence: ^rawptr) -> HRESULT,
	GetDeviceRemovedReason:           proc "stdcall" (this: ^IDevice) -> HRESULT,
	GetCopyableFootprints:            proc "stdcall" (this: ^IDevice, pResourceDesc: ^RESOURCE_DESC, FirstSubresource: u32, NumSubresources: u32, BaseOffset: u64, pLayouts: ^PLACED_SUBRESOURCE_FOOTPRINT, pNumRows: ^u32, pRowSizeInBytes: ^u64, pTotalBytes: ^u64),
	CreateQueryHeap:                  proc "stdcall" (this: ^IDevice, pDesc: ^QUERY_HEAP_DESC, riid: ^IID, ppvHeap: ^rawptr) -> HRESULT,
	SetStablePowerState:              proc "stdcall" (this: ^IDevice, Enable: BOOL) -> HRESULT,
	CreateCommandSignature:           proc "stdcall" (this: ^IDevice, pDesc: ^COMMAND_SIGNATURE_DESC, pRootSignature: ^IRootSignature, riid: ^IID, ppvCommandSignature: ^rawptr) -> HRESULT,
	GetResourceTiling:                proc "stdcall" (this: ^IDevice, pTiledResource: ^IResource, pNumTilesForEntireResource: ^u32, pPackedMipDesc: ^PACKED_MIP_INFO, pStandardTileShapeForNonPackedMips: ^TILE_SHAPE, pNumSubresourceTilings: ^u32, FirstSubresourceTilingToGet: u32, pSubresourceTilingsForNonPackedMips: ^SUBRESOURCE_TILING),
	GetAdapterLuid:                   proc "stdcall" (this: ^IDevice) -> LUID,
}


IPipelineLibrary_UUID :: "c64226a8-9201-46af-b4cc-53fb9ff7414f"
IPipelineLibrary :: struct #raw_union {
	#subtype id3d12devicechild: IDeviceChild,
	using id3d12pipelinelibrary_vtable: ^IPipelineLibrary_VTable,
}
IPipelineLibrary_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	StorePipeline:        proc "stdcall" (this: ^IPipelineLibrary, pName: [^]u16, pPipeline: ^IPipelineState) -> HRESULT,
	LoadGraphicsPipeline: proc "stdcall" (this: ^IPipelineLibrary, pName: [^]u16, pDesc: ^GRAPHICS_PIPELINE_STATE_DESC, riid: ^IID, ppPipelineState: ^rawptr) -> HRESULT,
	LoadComputePipeline:  proc "stdcall" (this: ^IPipelineLibrary, pName: [^]u16, pDesc: ^COMPUTE_PIPELINE_STATE_DESC, riid: ^IID, ppPipelineState: ^rawptr) -> HRESULT,
	GetSerializedSize:    proc "stdcall" (this: ^IPipelineLibrary) -> SIZE_T,
	Serialize:            proc "stdcall" (this: ^IPipelineLibrary, pData: rawptr, DataSizeInBytes: SIZE_T) -> HRESULT,
}


IPipelineLibrary1_UUID :: "80eabf42-2568-4e5e-bd82-c37f86961dc3"
IPipelineLibrary1 :: struct #raw_union {
	#subtype id3d12pipelinelibrary: IPipelineLibrary,
	using id3d12pipelinelibrary1_vtable: ^IPipelineLibrary1_VTable,
}
IPipelineLibrary1_VTable :: struct {
	using id3d12pipelinelibrary_vtable: IPipelineLibrary_VTable,
	LoadPipeline: proc "stdcall" (this: ^IPipelineLibrary1, pName: [^]u16, pDesc: ^PIPELINE_STATE_STREAM_DESC, riid: ^IID, ppPipelineState: ^rawptr) -> HRESULT,
}

MULTIPLE_FENCE_WAIT_FLAGS :: enum u32 { // TODO: make bit_set
	NONE = 0x0,
	ANY  = 0x1,
	ALL  = 0x0,
}

RESIDENCY_PRIORITY :: enum i32 {
	MINIMUM = 671088640,
	LOW     = 1342177280,
	NORMAL  = 2013265920,
	HIGH    = -1610547200,
	MAXIMUM = -939524096,
}


IDevice1_UUID :: "77acce80-638e-4e65-8895-c1f23386863e"
IDevice1 :: struct #raw_union {
	#subtype id3d12device: IDevice,
	using id3d12device1_vtable: ^IDevice1_VTable,
}
IDevice1_VTable :: struct {
	using id3d12device_vtable: IDevice_VTable,
	CreatePipelineLibrary:             proc "stdcall" (this: ^IDevice1, pLibraryBlob: rawptr, BlobLength: SIZE_T, riid: ^IID, ppPipelineLibrary: ^rawptr) -> HRESULT,
	SetEventOnMultipleFenceCompletion: proc "stdcall" (this: ^IDevice1, ppFences: ^^IFence, pFenceValues: ^u64, NumFences: u32, Flags: MULTIPLE_FENCE_WAIT_FLAGS, hEvent: HANDLE) -> HRESULT,
	SetResidencyPriority:              proc "stdcall" (this: ^IDevice1, NumObjects: u32, ppObjects: ^^IPageable, pPriorities: ^RESIDENCY_PRIORITY) -> HRESULT,
}


IDevice2_UUID :: "30baa41e-b15b-475c-a0bb-1af5c5b64328"
IDevice2 :: struct #raw_union {
	#subtype id3d12device1: IDevice1,
	using id3d12device2_vtable: ^IDevice2_VTable,
}
IDevice2_VTable :: struct {
	using id3d12device1_vtable: IDevice1_VTable,
	CreatePipelineState: proc "stdcall" (this: ^IDevice2, pDesc: ^PIPELINE_STATE_STREAM_DESC, riid: ^IID, ppPipelineState: ^rawptr) -> HRESULT,
}

RESIDENCY_FLAGS :: enum u32 { // TODO: make bit_set
	NONE            = 0x0,
	DENY_OVERBUDGET = 0x1,
}


IDevice3_UUID :: "81dadc15-2bad-4392-93c5-101345c4aa98"
IDevice3 :: struct #raw_union {
	#subtype id3d12device2: IDevice2,
	using id3d12device3_vtable: ^IDevice3_VTable,
}
IDevice3_VTable :: struct {
	using id3d12device2_vtable: IDevice2_VTable,
	OpenExistingHeapFromAddress:     proc "stdcall" (this: ^IDevice3, pAddress: rawptr, riid: ^IID, ppvHeap: ^rawptr) -> HRESULT,
	OpenExistingHeapFromFileMapping: proc "stdcall" (this: ^IDevice3, hFileMapping: HANDLE, riid: ^IID, ppvHeap: ^rawptr) -> HRESULT,
	EnqueueMakeResident:             proc "stdcall" (this: ^IDevice3, Flags: RESIDENCY_FLAGS, NumObjects: u32, ppObjects: ^^IPageable, pFenceToSignal: ^IFence, FenceValueToSignal: u64) -> HRESULT,
}

COMMAND_LIST_FLAGS :: enum u32 { // TODO: make bit_set
	COMMAND_LIST_FLAG_NONE = 0x0,
}

COMMAND_POOL_FLAGS :: enum u32 { // TODO: make bit_set
	COMMAND_POOL_FLAG_NONE = 0x0,
}

COMMAND_RECORDER_FLAGS :: enum u32 { // TODO: make bit_set
	COMMAND_RECORDER_FLAG_NONE = 0x0,
}

PROTECTED_SESSION_STATUS :: enum i32 {
	OK      = 0,
	INVALID = 1,
}


IProtectedSession_UUID :: "A1533D18-0AC1-4084-85B9-89A96116806B"
IProtectedSession :: struct #raw_union {
	#subtype id3d12devicechild: IDeviceChild,
	using id3d12protectedsession_vtable: ^IProtectedSession_VTable,
}
IProtectedSession_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	GetStatusFence:   proc "stdcall" (this: ^IProtectedSession, riid: ^IID, ppFence: ^rawptr) -> HRESULT,
	GetSessionStatus: proc "stdcall" (this: ^IProtectedSession) -> PROTECTED_SESSION_STATUS,
}

PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS :: enum u32 { // TODO: make bit_set
	NONE      = 0x0,
	SUPPORTED = 0x1,
}

FEATURE_DATA_PROTECTED_RESOURCE_SESSION_SUPPORT :: struct {
	NodeIndex: u32,
	Support:   PROTECTED_RESOURCE_SESSION_SUPPORT_FLAGS,
}

PROTECTED_RESOURCE_SESSION_FLAGS :: enum u32 { // TODO: make bit_set
	PROTECTED_RESOURCE_SESSION_FLAG_NONE = 0x0,
}

PROTECTED_RESOURCE_SESSION_DESC :: struct {
	NodeMask: u32,
	Flags:    PROTECTED_RESOURCE_SESSION_FLAGS,
}


IProtectedResourceSession_UUID :: "6CD696F4-F289-40CC-8091-5A6C0A099C3D"
IProtectedResourceSession :: struct #raw_union {
	#subtype id3d12protectedsession: IProtectedSession,
	using id3d12protectedresourcesession_vtable: ^IProtectedResourceSession_VTable,
}
IProtectedResourceSession_VTable :: struct {
	using id3d12protectedsession_vtable: IProtectedSession_VTable,
	GetDesc: proc "stdcall" (this: ^IProtectedResourceSession) -> PROTECTED_RESOURCE_SESSION_DESC,
}


IDevice4_UUID :: "e865df17-a9ee-46f9-a463-3098315aa2e5"
IDevice4 :: struct #raw_union {
	#subtype id3d12device3: IDevice3,
	using id3d12device4_vtable: ^IDevice4_VTable,
}
IDevice4_VTable :: struct {
	using id3d12device3_vtable: IDevice3_VTable,
	CreateCommandList1:             proc "stdcall" (this: ^IDevice4, nodeMask: u32, type: COMMAND_LIST_TYPE, flags: COMMAND_LIST_FLAGS, riid: ^IID, ppCommandList: ^rawptr) -> HRESULT,
	CreateProtectedResourceSession: proc "stdcall" (this: ^IDevice4, pDesc: ^PROTECTED_RESOURCE_SESSION_DESC, riid: ^IID, ppSession: ^rawptr) -> HRESULT,
	CreateCommittedResource1:       proc "stdcall" (this: ^IDevice4, pHeapProperties: ^HEAP_PROPERTIES, HeapFlags: HEAP_FLAGS, pDesc: ^RESOURCE_DESC, InitialResourceState: RESOURCE_STATES, pOptimizedClearValue: ^CLEAR_VALUE, pProtectedSession: ^IProtectedResourceSession, riidResource: ^IID, ppvResource: ^rawptr) -> HRESULT,
	CreateHeap1:                    proc "stdcall" (this: ^IDevice4, pDesc: ^HEAP_DESC, pProtectedSession: ^IProtectedResourceSession, riid: ^IID, ppvHeap: ^rawptr) -> HRESULT,
	CreateReservedResource1:        proc "stdcall" (this: ^IDevice4, pDesc: ^RESOURCE_DESC, InitialState: RESOURCE_STATES, pOptimizedClearValue: ^CLEAR_VALUE, pProtectedSession: ^IProtectedResourceSession, riid: ^IID, ppvResource: ^rawptr) -> HRESULT,
	GetResourceAllocationInfo1:     proc "stdcall" (this: ^IDevice4, visibleMask: u32, numResourceDescs: u32, pResourceDescs: ^RESOURCE_DESC, pResourceAllocationInfo1: ^RESOURCE_ALLOCATION_INFO1) -> RESOURCE_ALLOCATION_INFO,
}

LIFETIME_STATE :: enum i32 {
	IN_USE     = 0,
	NOT_IN_USE = 1,
}


ILifetimeOwner_UUID :: "e667af9f-cd56-4f46-83ce-032e595d70a8"
ILifetimeOwner :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12lifetimeowner_vtable: ^ILifetimeOwner_VTable,
}
ILifetimeOwner_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	LifetimeStateUpdated: proc "stdcall" (this: ^ILifetimeOwner, NewState: LIFETIME_STATE),
}


ISwapChainAssistant_UUID :: "f1df64b6-57fd-49cd-8807-c0eb88b45c8f"
ISwapChainAssistant :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12swapchainassistant_vtable: ^ISwapChainAssistant_VTable,
}
ISwapChainAssistant_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetLUID:                           proc "stdcall" (this: ^ISwapChainAssistant) -> LUID,
	GetSwapChainObject:                proc "stdcall" (this: ^ISwapChainAssistant, riid: ^IID, ppv: ^rawptr) -> HRESULT,
	GetCurrentResourceAndCommandQueue: proc "stdcall" (this: ^ISwapChainAssistant, riidResource: ^IID, ppvResource: ^rawptr, riidQueue: ^IID, ppvQueue: ^rawptr) -> HRESULT,
	InsertImplicitSync:                proc "stdcall" (this: ^ISwapChainAssistant) -> HRESULT,
}


ILifetimeTracker_UUID :: "3fd03d36-4eb1-424a-a582-494ecb8ba813"
ILifetimeTracker :: struct #raw_union {
	#subtype id3d12devicechild: IDeviceChild,
	using id3d12lifetimetracker_vtable: ^ILifetimeTracker_VTable,
}
ILifetimeTracker_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	DestroyOwnedObject: proc "stdcall" (this: ^ILifetimeTracker, pObject: ^IDeviceChild) -> HRESULT,
}

META_COMMAND_PARAMETER_TYPE :: enum i32 {
	FLOAT                                       = 0,
	UINT64                                      = 1,
	GPU_VIRTUAL_ADDRESS                         = 2,
	CPU_DESCRIPTOR_HANDLE_HEAP_TYPE_CBV_SRV_UAV = 3,
	GPU_DESCRIPTOR_HANDLE_HEAP_TYPE_CBV_SRV_UAV = 4,
}

META_COMMAND_PARAMETER_FLAGS :: enum u32 { // TODO: make bit_set
	INPUT  = 0x1,
	OUTPUT = 0x2,
}

META_COMMAND_PARAMETER_STAGE :: enum i32 {
	CREATION       = 0,
	INITIALIZATION = 1,
	EXECUTION      = 2,
}

META_COMMAND_PARAMETER_DESC :: struct {
	Name:                  [^]u16,
	Type:                  META_COMMAND_PARAMETER_TYPE,
	Flags:                 META_COMMAND_PARAMETER_FLAGS,
	RequiredResourceState: RESOURCE_STATES,
	StructureOffset:       u32,
}

GRAPHICS_STATES :: enum i32 {
	NONE                    = 0,
	IA_VERTEX_BUFFERS       = 1,
	IA_INDEX_BUFFER         = 2,
	IA_PRIMITIVE_TOPOLOGY   = 4,
	DESCRIPTOR_HEAP         = 8,
	GRAPHICS_ROOT_SIGNATURE = 16,
	COMPUTE_ROOT_SIGNATURE  = 32,
	RS_VIEWPORTS            = 64,
	RS_SCISSOR_RECTS        = 128,
	PREDICATION             = 256,
	OM_RENDER_TARGETS       = 512,
	OM_STENCIL_REF          = 1024,
	OM_BLEND_FACTOR         = 2048,
	PIPELINE_STATE          = 4096,
	SO_TARGETS              = 8192,
	OM_DEPTH_BOUNDS         = 16384,
	SAMPLE_POSITIONS        = 32768,
	VIEW_INSTANCE_MASK      = 65536,
}

META_COMMAND_DESC :: struct {
	Id:                       GUID,
	Name:                     [^]u16,
	InitializationDirtyState: GRAPHICS_STATES,
	ExecutionDirtyState:      GRAPHICS_STATES,
}


IStateObject_UUID :: "47016943-fca8-4594-93ea-af258b55346d"
IStateObject :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
}


IStateObjectProperties_UUID :: "de5fa827-9bf9-4f26-89ff-d7f56fde3860"
IStateObjectProperties :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12stateobjectproperties_vtable: ^IStateObjectProperties_VTable,
}
IStateObjectProperties_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetShaderIdentifier:  proc "stdcall" (this: ^IStateObjectProperties, pExportName: [^]u16) -> rawptr,
	GetShaderStackSize:   proc "stdcall" (this: ^IStateObjectProperties, pExportName: [^]u16) -> u64,
	GetPipelineStackSize: proc "stdcall" (this: ^IStateObjectProperties) -> u64,
	SetPipelineStackSize: proc "stdcall" (this: ^IStateObjectProperties, PipelineStackSizeInBytes: u64),
}

STATE_SUBOBJECT_TYPE :: enum i32 {
	STATE_OBJECT_CONFIG                   = 0,
	GLOBAL_ROOT_SIGNATURE                 = 1,
	LOCAL_ROOT_SIGNATURE                  = 2,
	NODE_MASK                             = 3,
	DXIL_LIBRARY                          = 5,
	EXISTING_COLLECTION                   = 6,
	SUBOBJECT_TO_EXPORTS_ASSOCIATION      = 7,
	DXIL_SUBOBJECT_TO_EXPORTS_ASSOCIATION = 8,
	RAYTRACING_SHADER_CONFIG              = 9,
	RAYTRACING_PIPELINE_CONFIG            = 10,
	HIT_GROUP                             = 11,
	RAYTRACING_PIPELINE_CONFIG1           = 12,
	MAX_VALID                             = 13,
}

STATE_SUBOBJECT :: struct {
	Type:  STATE_SUBOBJECT_TYPE,
	pDesc: rawptr,
}

STATE_OBJECT_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                                             = 0x0,
	ALLOW_LOCAL_DEPENDENCIES_ON_EXTERNAL_DEFINITIONS = 0x1,
	ALLOW_EXTERNAL_DEPENDENCIES_ON_LOCAL_DEFINITIONS = 0x2,
	ALLOW_STATE_OBJECT_ADDITIONS                     = 0x4,
}

STATE_OBJECT_CONFIG :: struct {
	Flags: STATE_OBJECT_FLAGS,
}

GLOBAL_ROOT_SIGNATURE :: struct {
	pGlobalRootSignature: ^IRootSignature,
}

LOCAL_ROOT_SIGNATURE :: struct {
	pLocalRootSignature: ^IRootSignature,
}

NODE_MASK :: struct {
	NodeMask: u32,
}

EXPORT_FLAGS :: enum u32 { // TODO: make bit_set
	EXPORT_FLAG_NONE = 0x0,
}

EXPORT_DESC :: struct {
	Name:           [^]u16,
	ExportToRename: [^]u16,
	Flags:          EXPORT_FLAGS,
}

DXIL_LIBRARY_DESC :: struct {
	DXILLibrary: SHADER_BYTECODE,
	NumExports:  u32,
	pExports:    ^EXPORT_DESC,
}

EXISTING_COLLECTION_DESC :: struct {
	pExistingCollection: ^IStateObject,
	NumExports:          u32,
	pExports:            ^EXPORT_DESC,
}

SUBOBJECT_TO_EXPORTS_ASSOCIATION :: struct {
	pSubobjectToAssociate: ^STATE_SUBOBJECT,
	NumExports:            u32,
	pExports:              [^]^i16,
}

DXIL_SUBOBJECT_TO_EXPORTS_ASSOCIATION :: struct {
	SubobjectToAssociate: ^i16,
	NumExports:           u32,
	pExports:             [^]^i16,
}

HIT_GROUP_TYPE :: enum i32 {
	TRIANGLES            = 0,
	PROCEDURAL_PRIMITIVE = 1,
}

HIT_GROUP_DESC :: struct {
	HitGroupExport:           ^i16,
	Type:                     HIT_GROUP_TYPE,
	AnyHitShaderImport:       ^i16,
	ClosestHitShaderImport:   ^i16,
	IntersectionShaderImport: ^i16,
}

RAYTRACING_SHADER_CONFIG :: struct {
	MaxPayloadSizeInBytes:   u32,
	MaxAttributeSizeInBytes: u32,
}

RAYTRACING_PIPELINE_CONFIG :: struct {
	MaxTraceRecursionDepth: u32,
}

RAYTRACING_PIPELINE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                       = 0x0,
	SKIP_TRIANGLES             = 0x100,
	SKIP_PROCEDURAL_PRIMITIVES = 0x200,
}

RAYTRACING_PIPELINE_CONFIG1 :: struct {
	MaxTraceRecursionDepth: u32,
	Flags:                  RAYTRACING_PIPELINE_FLAGS,
}

STATE_OBJECT_TYPE :: enum i32 {
	COLLECTION          = 0,
	RAYTRACING_PIPELINE = 3,
}

STATE_OBJECT_DESC :: struct {
	Type:          STATE_OBJECT_TYPE,
	NumSubobjects: u32,
	pSubobjects:   ^STATE_SUBOBJECT,
}

RAYTRACING_GEOMETRY_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                           = 0x0,
	OPAQUE                         = 0x1,
	NO_DUPLICATE_ANYHIT_INVOCATION = 0x2,
}

RAYTRACING_GEOMETRY_TYPE :: enum i32 {
	TRIANGLES                  = 0,
	PROCEDURAL_PRIMITIVE_AABBS = 1,
}

RAYTRACING_INSTANCE_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                            = 0x0,
	TRIANGLE_CULL_DISABLE           = 0x1,
	TRIANGLE_FRONT_COUNTERCLOCKWISE = 0x2,
	FORCE_OPAQUE                    = 0x4,
	FORCE_NON_OPAQUE                = 0x8,
}

GPU_VIRTUAL_ADDRESS_AND_STRIDE :: struct {
	StartAddress:  GPU_VIRTUAL_ADDRESS,
	StrideInBytes: u64,
}

GPU_VIRTUAL_ADDRESS_RANGE :: struct {
	StartAddress: GPU_VIRTUAL_ADDRESS,
	SizeInBytes:  u64,
}

GPU_VIRTUAL_ADDRESS_RANGE_AND_STRIDE :: struct {
	StartAddress:  GPU_VIRTUAL_ADDRESS,
	SizeInBytes:   u64,
	StrideInBytes: u64,
}

RAYTRACING_GEOMETRY_TRIANGLES_DESC :: struct {
	Transform3x4: GPU_VIRTUAL_ADDRESS,
	IndexFormat:  dxgi.FORMAT,
	VertexFormat: dxgi.FORMAT,
	IndexCount:   u32,
	VertexCount:  u32,
	IndexBuffer:  GPU_VIRTUAL_ADDRESS,
	VertexBuffer: GPU_VIRTUAL_ADDRESS_AND_STRIDE,
}

RAYTRACING_AABB :: struct {
	MinX: f32,
	MinY: f32,
	MinZ: f32,
	MaxX: f32,
	MaxY: f32,
	MaxZ: f32,
}

RAYTRACING_GEOMETRY_AABBS_DESC :: struct {
	AABBCount: u64,
	AABBs:     GPU_VIRTUAL_ADDRESS_AND_STRIDE,
}

RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS :: enum u32 { // TODO: make bit_set
	NONE              = 0x0,
	ALLOW_UPDATE      = 0x1,
	ALLOW_COMPACTION  = 0x2,
	PREFER_FAST_TRACE = 0x4,
	PREFER_FAST_BUILD = 0x8,
	MINIMIZE_MEMORY   = 0x10,
	PERFORM_UPDATE    = 0x20,
}

RAYTRACING_ACCELERATION_STRUCTURE_COPY_MODE :: enum i32 {
	CLONE                          = 0,
	COMPACT                        = 1,
	VISUALIZATION_DECODE_FOR_TOOLS = 2,
	SERIALIZE                      = 3,
	DESERIALIZE                    = 4,
}

RAYTRACING_ACCELERATION_STRUCTURE_TYPE :: enum i32 {
	TOP_LEVEL    = 0,
	BOTTOM_LEVEL = 1,
}

ELEMENTS_LAYOUT :: enum i32 {
	ARRAY             = 0,
	ARRAY_OF_POINTERS = 1,
}

RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_TYPE :: enum i32 {
	COMPACTED_SIZE      = 0,
	TOOLS_VISUALIZATION = 1,
	SERIALIZATION       = 2,
	CURRENT_SIZE        = 3,
}

RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_DESC :: struct {
	DestBuffer: GPU_VIRTUAL_ADDRESS,
	InfoType:   RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_TYPE,
}

RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_COMPACTED_SIZE_DESC :: struct {
	CompactedSizeInBytes: u64,
}

RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_TOOLS_VISUALIZATION_DESC :: struct {
	DecodedSizeInBytes: u64,
}

BUILD_RAYTRACING_ACCELERATION_STRUCTURE_TOOLS_VISUALIZATION_HEADER :: struct {
	Type:     RAYTRACING_ACCELERATION_STRUCTURE_TYPE,
	NumDescs: u32,
}

RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_SERIALIZATION_DESC :: struct {
	SerializedSizeInBytes:                       u64,
	NumBottomLevelAccelerationStructurePointers: u64,
}

SERIALIZED_DATA_DRIVER_MATCHING_IDENTIFIER :: struct {
	DriverOpaqueGUID:           GUID,
	DriverOpaqueVersioningData: [16]u8,
}

SERIALIZED_DATA_TYPE :: enum i32 {
	SERIALIZED_DATA_RAYTRACING_ACCELERATION_STRUCTURE = 0,
}

DRIVER_MATCHING_IDENTIFIER_STATUS :: enum i32 {
	COMPATIBLE_WITH_DEVICE = 0,
	UNSUPPORTED_TYPE       = 1,
	UNRECOGNIZED           = 2,
	INCOMPATIBLE_VERSION   = 3,
	INCOMPATIBLE_TYPE      = 4,
}

SERIALIZED_RAYTRACING_ACCELERATION_STRUCTURE_HEADER :: struct {
	DriverMatchingIdentifier:                               SERIALIZED_DATA_DRIVER_MATCHING_IDENTIFIER,
	SerializedSizeInBytesIncludingHeader:                   u64,
	DeserializedSizeInBytes:                                u64,
	NumBottomLevelAccelerationStructurePointersAfterHeader: u64,
}

RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_CURRENT_SIZE_DESC :: struct {
	CurrentSizeInBytes: u64,
}

RAYTRACING_INSTANCE_DESC :: struct {
	Transform:                           [3][4]f32,
	InstanceID:                          u32,
	InstanceContributionToHitGroupIndex: u32,
	AccelerationStructure:               GPU_VIRTUAL_ADDRESS,
}

RAYTRACING_GEOMETRY_DESC :: struct {
	Type:  RAYTRACING_GEOMETRY_TYPE,
	Flags: RAYTRACING_GEOMETRY_FLAGS,
	using _: struct #raw_union {
		Triangles: RAYTRACING_GEOMETRY_TRIANGLES_DESC,
		AABBs:     RAYTRACING_GEOMETRY_AABBS_DESC,
	},
}

BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INPUTS :: struct {
	Type:        RAYTRACING_ACCELERATION_STRUCTURE_TYPE,
	Flags:       RAYTRACING_ACCELERATION_STRUCTURE_BUILD_FLAGS,
	NumDescs:    u32,
	DescsLayout: ELEMENTS_LAYOUT,
	using _: struct #raw_union {
		InstanceDescs:   GPU_VIRTUAL_ADDRESS,
		pGeometryDescs:  ^RAYTRACING_GEOMETRY_DESC,
		ppGeometryDescs: ^^RAYTRACING_GEOMETRY_DESC,
	},
}

BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC :: struct {
	DestAccelerationStructureData:    GPU_VIRTUAL_ADDRESS,
	Inputs:                           BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INPUTS,
	SourceAccelerationStructureData:  GPU_VIRTUAL_ADDRESS,
	ScratchAccelerationStructureData: GPU_VIRTUAL_ADDRESS,
}

RAYTRACING_ACCELERATION_STRUCTURE_PREBUILD_INFO :: struct {
	ResultDataMaxSizeInBytes:     u64,
	ScratchDataSizeInBytes:       u64,
	UpdateScratchDataSizeInBytes: u64,
}

RAY_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                            = 0x0,
	FORCE_OPAQUE                    = 0x1,
	FORCE_NON_OPAQUE                = 0x2,
	ACCEPT_FIRST_HIT_AND_END_SEARCH = 0x4,
	SKIP_CLOSEST_HIT_SHADER         = 0x8,
	CULL_BACK_FACING_TRIANGLES      = 0x10,
	CULL_FRONT_FACING_TRIANGLES     = 0x20,
	CULL_OPAQUE                     = 0x40,
	CULL_NON_OPAQUE                 = 0x80,
	SKIP_TRIANGLES                  = 0x100,
	SKIP_PROCEDURAL_PRIMITIVES      = 0x200,
}

HIT_KIND :: enum i32 {
	TRIANGLE_FRONT_FACE = 254,
	TRIANGLE_BACK_FACE  = 255,
}


IDevice5_UUID :: "8b4f173b-2fea-4b80-8f58-4307191ab95d"
IDevice5 :: struct #raw_union {
	#subtype id3d12device4: IDevice4,
	using id3d12device5_vtable: ^IDevice5_VTable,
}
IDevice5_VTable :: struct {
	using id3d12device4_vtable: IDevice4_VTable,
	CreateLifetimeTracker:                          proc "stdcall" (this: ^IDevice5, pOwner: ^ILifetimeOwner, riid: ^IID, ppvTracker: ^rawptr) -> HRESULT,
	RemoveDevice:                                   proc "stdcall" (this: ^IDevice5),
	EnumerateMetaCommands:                          proc "stdcall" (this: ^IDevice5, pNumMetaCommands: ^u32, pDescs: ^META_COMMAND_DESC) -> HRESULT,
	EnumerateMetaCommandParameters:                 proc "stdcall" (this: ^IDevice5, CommandId: ^GUID, Stage: META_COMMAND_PARAMETER_STAGE, pTotalStructureSizeInBytes: ^u32, pParameterCount: ^u32, pParameterDescs: ^META_COMMAND_PARAMETER_DESC) -> HRESULT,
	CreateMetaCommand:                              proc "stdcall" (this: ^IDevice5, CommandId: ^GUID, NodeMask: u32, pCreationParametersData: rawptr, CreationParametersDataSizeInBytes: SIZE_T, riid: ^IID, ppMetaCommand: ^rawptr) -> HRESULT,
	CreateStateObject:                              proc "stdcall" (this: ^IDevice5, pDesc: ^STATE_OBJECT_DESC, riid: ^IID, ppStateObject: ^rawptr) -> HRESULT,
	GetRaytracingAccelerationStructurePrebuildInfo: proc "stdcall" (this: ^IDevice5, pDesc: ^BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INPUTS, pInfo: ^RAYTRACING_ACCELERATION_STRUCTURE_PREBUILD_INFO),
	CheckDriverMatchingIdentifier:                  proc "stdcall" (this: ^IDevice5, SerializedDataType: SERIALIZED_DATA_TYPE, pIdentifierToCheck: ^SERIALIZED_DATA_DRIVER_MATCHING_IDENTIFIER) -> DRIVER_MATCHING_IDENTIFIER_STATUS,
}

AUTO_BREADCRUMB_OP :: enum i32 {
	SETMARKER                                        = 0,
	BEGINEVENT                                       = 1,
	ENDEVENT                                         = 2,
	DRAWINSTANCED                                    = 3,
	DRAWINDEXEDINSTANCED                             = 4,
	EXECUTEINDIRECT                                  = 5,
	DISPATCH                                         = 6,
	COPYBUFFERREGION                                 = 7,
	COPYTEXTUREREGION                                = 8,
	COPYRESOURCE                                     = 9,
	COPYTILES                                        = 10,
	RESOLVESUBRESOURCE                               = 11,
	CLEARRENDERTARGETVIEW                            = 12,
	CLEARUNORDEREDACCESSVIEW                         = 13,
	CLEARDEPTHSTENCILVIEW                            = 14,
	RESOURCEBARRIER                                  = 15,
	EXECUTEBUNDLE                                    = 16,
	PRESENT                                          = 17,
	RESOLVEQUERYDATA                                 = 18,
	BEGINSUBMISSION                                  = 19,
	ENDSUBMISSION                                    = 20,
	DECODEFRAME                                      = 21,
	PROCESSFRAMES                                    = 22,
	ATOMICCOPYBUFFERUINT                             = 23,
	ATOMICCOPYBUFFERUINT64                           = 24,
	RESOLVESUBRESOURCEREGION                         = 25,
	WRITEBUFFERIMMEDIATE                             = 26,
	DECODEFRAME1                                     = 27,
	SETPROTECTEDRESOURCESESSION                      = 28,
	DECODEFRAME2                                     = 29,
	PROCESSFRAMES1                                   = 30,
	BUILDRAYTRACINGACCELERATIONSTRUCTURE             = 31,
	EMITRAYTRACINGACCELERATIONSTRUCTUREPOSTBUILDINFO = 32,
	COPYRAYTRACINGACCELERATIONSTRUCTURE              = 33,
	DISPATCHRAYS                                     = 34,
	INITIALIZEMETACOMMAND                            = 35,
	EXECUTEMETACOMMAND                               = 36,
	ESTIMATEMOTION                                   = 37,
	RESOLVEMOTIONVECTORHEAP                          = 38,
	SETPIPELINESTATE1                                = 39,
	INITIALIZEEXTENSIONCOMMAND                       = 40,
	EXECUTEEXTENSIONCOMMAND                          = 41,
	DISPATCHMESH                                     = 42,
}

AUTO_BREADCRUMB_NODE :: struct {
	pCommandListDebugNameA:  cstring,
	pCommandListDebugNameW:  [^]u16,
	pCommandQueueDebugNameA: cstring,
	pCommandQueueDebugNameW: [^]u16,
	pCommandList:            ^IGraphicsCommandList,
	pCommandQueue:           ^ICommandQueue,
	BreadcrumbCount:         u32,
	pLastBreadcrumbValue:    ^u32,
	pCommandHistory:         ^AUTO_BREADCRUMB_OP,
	pNext:                   ^AUTO_BREADCRUMB_NODE,
}

DRED_BREADCRUMB_CONTEXT :: struct {
	BreadcrumbIndex: u32,
	pContextString:  [^]u16,
}

AUTO_BREADCRUMB_NODE1 :: struct {
	pCommandListDebugNameA:  cstring,
	pCommandListDebugNameW:  [^]u16,
	pCommandQueueDebugNameA: cstring,
	pCommandQueueDebugNameW: [^]u16,
	pCommandList:            ^IGraphicsCommandList,
	pCommandQueue:           ^ICommandQueue,
	BreadcrumbCount:         u32,
	pLastBreadcrumbValue:    ^u32,
	pCommandHistory:         ^AUTO_BREADCRUMB_OP,
	pNext:                   ^AUTO_BREADCRUMB_NODE1,
	BreadcrumbContextsCount: u32,
	pBreadcrumbContexts:     ^DRED_BREADCRUMB_CONTEXT,
}

DRED_VERSION :: enum i32 {
	_1_0 = 1,
	_1_1 = 2,
	_1_2 = 3,
}

DRED_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                    = 0x0,
	FORCE_ENABLE            = 0x1,
	DISABLE_AUTOBREADCRUMBS = 0x2,
}

DRED_ENABLEMENT :: enum i32 {
	SYSTEM_CONTROLLED = 0,
	FORCED_OFF        = 1,
	FORCED_ON         = 2,
}

DEVICE_REMOVED_EXTENDED_DATA :: struct {
	Flags:                   DRED_FLAGS,
	pHeadAutoBreadcrumbNode: ^AUTO_BREADCRUMB_NODE,
}

DRED_ALLOCATION_TYPE :: enum i32 {
	COMMAND_QUEUE            = 19,
	COMMAND_ALLOCATOR        = 20,
	PIPELINE_STATE           = 21,
	COMMAND_LIST             = 22,
	FENCE                    = 23,
	DESCRIPTOR_HEAP          = 24,
	HEAP                     = 25,
	QUERY_HEAP               = 27,
	COMMAND_SIGNATURE        = 28,
	PIPELINE_LIBRARY         = 29,
	VIDEO_DECODER            = 30,
	VIDEO_PROCESSOR          = 32,
	RESOURCE                 = 34,
	PASS                     = 35,
	CRYPTOSESSION            = 36,
	CRYPTOSESSIONPOLICY      = 37,
	PROTECTEDRESOURCESESSION = 38,
	VIDEO_DECODER_HEAP       = 39,
	COMMAND_POOL             = 40,
	COMMAND_RECORDER         = 41,
	STATE_OBJECT             = 42,
	METACOMMAND              = 43,
	SCHEDULINGGROUP          = 44,
	VIDEO_MOTION_ESTIMATOR   = 45,
	VIDEO_MOTION_VECTOR_HEAP = 46,
	VIDEO_EXTENSION_COMMAND  = 47,
	INVALID                  = -1,
}

DRED_ALLOCATION_NODE :: struct {
	ObjectNameA:    cstring,
	ObjectNameW:    ^i16,
	AllocationType: DRED_ALLOCATION_TYPE,
	pNext:          ^DRED_ALLOCATION_NODE,
}

DRED_ALLOCATION_NODE1 :: struct {
	ObjectNameA:    cstring,
	ObjectNameW:    ^i16,
	AllocationType: DRED_ALLOCATION_TYPE,
	pNext:          ^DRED_ALLOCATION_NODE1,
	pObject:        ^IUnknown,
}

DRED_AUTO_BREADCRUMBS_OUTPUT :: struct {
	pHeadAutoBreadcrumbNode: ^AUTO_BREADCRUMB_NODE,
}

DRED_AUTO_BREADCRUMBS_OUTPUT1 :: struct {
	pHeadAutoBreadcrumbNode: ^AUTO_BREADCRUMB_NODE1,
}

DRED_PAGE_FAULT_OUTPUT :: struct {
	PageFaultVA:                    GPU_VIRTUAL_ADDRESS,
	pHeadExistingAllocationNode:    ^DRED_ALLOCATION_NODE,
	pHeadRecentFreedAllocationNode: ^DRED_ALLOCATION_NODE,
}

DRED_PAGE_FAULT_OUTPUT1 :: struct {
	PageFaultVA:                    GPU_VIRTUAL_ADDRESS,
	pHeadExistingAllocationNode:    ^DRED_ALLOCATION_NODE1,
	pHeadRecentFreedAllocationNode: ^DRED_ALLOCATION_NODE1,
}

DEVICE_REMOVED_EXTENDED_DATA1 :: struct {
	DeviceRemovedReason:   HRESULT,
	AutoBreadcrumbsOutput: DRED_AUTO_BREADCRUMBS_OUTPUT,
	PageFaultOutput:       DRED_PAGE_FAULT_OUTPUT,
}

DEVICE_REMOVED_EXTENDED_DATA2 :: struct {
	DeviceRemovedReason:   HRESULT,
	AutoBreadcrumbsOutput: DRED_AUTO_BREADCRUMBS_OUTPUT1,
	PageFaultOutput:       DRED_PAGE_FAULT_OUTPUT1,
}

VERSIONED_DEVICE_REMOVED_EXTENDED_DATA :: struct {
	Version: DRED_VERSION,
	using _: struct #raw_union {
		Dred_1_0: DEVICE_REMOVED_EXTENDED_DATA,
		Dred_1_1: DEVICE_REMOVED_EXTENDED_DATA1,
		Dred_1_2: DEVICE_REMOVED_EXTENDED_DATA2,
	},
}


IDeviceRemovedExtendedDataSettings_UUID :: "82BC481C-6B9B-4030-AEDB-7EE3D1DF1E63"
IDeviceRemovedExtendedDataSettings :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12deviceremovedextendeddatasettings_vtable: ^IDeviceRemovedExtendedDataSettings_VTable,
}
IDeviceRemovedExtendedDataSettings_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetAutoBreadcrumbsEnablement: proc "stdcall" (this: ^IDeviceRemovedExtendedDataSettings, Enablement: DRED_ENABLEMENT),
	SetPageFaultEnablement:       proc "stdcall" (this: ^IDeviceRemovedExtendedDataSettings, Enablement: DRED_ENABLEMENT),
	SetWatsonDumpEnablement:      proc "stdcall" (this: ^IDeviceRemovedExtendedDataSettings, Enablement: DRED_ENABLEMENT),
}


IDeviceRemovedExtendedDataSettings1_UUID :: "DBD5AE51-3317-4F0A-ADF9-1D7CEDCAAE0B"
IDeviceRemovedExtendedDataSettings1 :: struct #raw_union {
	#subtype id3d12deviceremovedextendeddatasettings: IDeviceRemovedExtendedDataSettings,
	using id3d12deviceremovedextendeddatasettings1_vtable: ^IDeviceRemovedExtendedDataSettings1_VTable,
}
IDeviceRemovedExtendedDataSettings1_VTable :: struct {
	using id3d12deviceremovedextendeddatasettings_vtable: IDeviceRemovedExtendedDataSettings_VTable,
	SetBreadcrumbContextEnablement: proc "stdcall" (this: ^IDeviceRemovedExtendedDataSettings1, Enablement: DRED_ENABLEMENT),
}


IDeviceRemovedExtendedData_UUID :: "98931D33-5AE8-4791-AA3C-1A73A2934E71"
IDeviceRemovedExtendedData :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12deviceremovedextendeddata_vtable: ^IDeviceRemovedExtendedData_VTable,
}
IDeviceRemovedExtendedData_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetAutoBreadcrumbsOutput:     proc "stdcall" (this: ^IDeviceRemovedExtendedData, pOutput: ^DRED_AUTO_BREADCRUMBS_OUTPUT) -> HRESULT,
	GetPageFaultAllocationOutput: proc "stdcall" (this: ^IDeviceRemovedExtendedData, pOutput: ^DRED_PAGE_FAULT_OUTPUT) -> HRESULT,
}


IDeviceRemovedExtendedData1_UUID :: "9727A022-CF1D-4DDA-9EBA-EFFA653FC506"
IDeviceRemovedExtendedData1 :: struct #raw_union {
	#subtype id3d12deviceremovedextendeddata: IDeviceRemovedExtendedData,
	using id3d12deviceremovedextendeddata1_vtable: ^IDeviceRemovedExtendedData1_VTable,
}
IDeviceRemovedExtendedData1_VTable :: struct {
	using id3d12deviceremovedextendeddata_vtable: IDeviceRemovedExtendedData_VTable,
	GetAutoBreadcrumbsOutput1:     proc "stdcall" (this: ^IDeviceRemovedExtendedData1, pOutput: ^DRED_AUTO_BREADCRUMBS_OUTPUT1) -> HRESULT,
	GetPageFaultAllocationOutput1: proc "stdcall" (this: ^IDeviceRemovedExtendedData1, pOutput: ^DRED_PAGE_FAULT_OUTPUT1) -> HRESULT,
}

BACKGROUND_PROCESSING_MODE :: enum i32 {
	ALLOWED                      = 0,
	ALLOW_INTRUSIVE_MEASUREMENTS = 1,
	DISABLE_BACKGROUND_WORK      = 2,
	DISABLE_PROFILING_BY_SYSTEM  = 3,
}

MEASUREMENTS_ACTION :: enum i32 {
	KEEP_ALL                     = 0,
	COMMIT_RESULTS               = 1,
	COMMIT_RESULTS_HIGH_PRIORITY = 2,
	DISCARD_PREVIOUS             = 3,
}


IDevice6_UUID :: "c70b221b-40e4-4a17-89af-025a0727a6dc"
IDevice6 :: struct #raw_union {
	#subtype id3d12device5: IDevice5,
	using id3d12device6_vtable: ^IDevice6_VTable,
}
IDevice6_VTable :: struct {
	using id3d12device5_vtable: IDevice5_VTable,
	SetBackgroundProcessingMode: proc "stdcall" (this: ^IDevice6, Mode: BACKGROUND_PROCESSING_MODE, MeasurementsAction: MEASUREMENTS_ACTION, hEventToSignalUponCompletion: HANDLE, pbFurtherMeasurementsDesired: ^BOOL) -> HRESULT,
}

FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPE_COUNT :: struct {
	NodeIndex: u32,
	Count:     u32,
}

FEATURE_DATA_PROTECTED_RESOURCE_SESSION_TYPES :: struct {
	NodeIndex: u32,
	Count:     u32,
	pTypes:    ^GUID,
}

PROTECTED_RESOURCE_SESSION_DESC1 :: struct {
	NodeMask:       u32,
	Flags:          PROTECTED_RESOURCE_SESSION_FLAGS,
	ProtectionType: GUID,
}


IProtectedResourceSession1_UUID :: "D6F12DD6-76FB-406E-8961-4296EEFC0409"
IProtectedResourceSession1 :: struct #raw_union {
	#subtype id3d12protectedresourcesession: IProtectedResourceSession,
	using id3d12protectedresourcesession1_vtable: ^IProtectedResourceSession1_VTable,
}
IProtectedResourceSession1_VTable :: struct {
	using id3d12protectedresourcesession_vtable: IProtectedResourceSession_VTable,
	GetDesc1: proc "stdcall" (this: ^IProtectedResourceSession1) -> PROTECTED_RESOURCE_SESSION_DESC1,
}


IDevice7_UUID :: "5c014b53-68a1-4b9b-8bd1-dd6046b9358b"
IDevice7 :: struct #raw_union {
	#subtype id3d12device6: IDevice6,
	using id3d12device7_vtable: ^IDevice7_VTable,
}
IDevice7_VTable :: struct {
	using id3d12device6_vtable: IDevice6_VTable,
	AddToStateObject: proc "stdcall" (this: ^IDevice7, pAddition: ^STATE_OBJECT_DESC, pStateObjectToGrowFrom: ^IStateObject, riid: ^IID, ppNewStateObject: ^rawptr) -> HRESULT,
	CreateProtectedResourceSession1: proc "stdcall" (this: ^IDevice7, pDesc: ^PROTECTED_RESOURCE_SESSION_DESC1, riid: ^IID, ppSession: ^rawptr) -> HRESULT,
}


IDevice8_UUID :: "9218E6BB-F944-4F7E-A75C-B1B2C7B701F3"
IDevice8 :: struct #raw_union {
	#subtype id3d12device7: IDevice7,
	using id3d12device8_vtable: ^IDevice8_VTable,
}
IDevice8_VTable :: struct {
	using id3d12device7_vtable: IDevice7_VTable,
	GetResourceAllocationInfo2:               proc "stdcall" (this: ^IDevice8, visibleMask: u32, numResourceDescs: u32, pResourceDescs: ^RESOURCE_DESC1, pResourceAllocationInfo1: ^RESOURCE_ALLOCATION_INFO1) -> RESOURCE_ALLOCATION_INFO,
	CreateCommittedResource2:                 proc "stdcall" (this: ^IDevice8, pHeapProperties: ^HEAP_PROPERTIES, HeapFlags: HEAP_FLAGS, pDesc: ^RESOURCE_DESC1, InitialResourceState: RESOURCE_STATES, pOptimizedClearValue: ^CLEAR_VALUE, pProtectedSession: ^IProtectedResourceSession, riidResource: ^IID, ppvResource: ^rawptr) -> HRESULT,
	CreatePlacedResource1:                    proc "stdcall" (this: ^IDevice8, pHeap: ^IHeap, HeapOffset: u64, pDesc: ^RESOURCE_DESC1, InitialState: RESOURCE_STATES, pOptimizedClearValue: ^CLEAR_VALUE, riid: ^IID, ppvResource: ^rawptr) -> HRESULT,
	CreateSamplerFeedbackUnorderedAccessView: proc "stdcall" (this: ^IDevice8, pTargetedResource: ^IResource, pFeedbackResource: ^IResource, DestDescriptor: CPU_DESCRIPTOR_HANDLE),
	GetCopyableFootprints1:                   proc "stdcall" (this: ^IDevice8, pResourceDesc: ^RESOURCE_DESC1, FirstSubresource: u32, NumSubresources: u32, BaseOffset: u64, pLayouts: ^PLACED_SUBRESOURCE_FOOTPRINT, pNumRows: ^u32, pRowSizeInBytes: ^u64, pTotalBytes: ^u64),
}


IResource1_UUID :: "9D5E227A-4430-4161-88B3-3ECA6BB16E19"
IResource1 :: struct #raw_union {
	#subtype id3d12resource: IResource,
	using id3d12resource1_vtable: ^IResource1_VTable,
}
IResource1_VTable :: struct {
	using id3d12resource_vtable: IResource_VTable,
	GetProtectedResourceSession: proc "stdcall" (this: ^IResource1, riid: ^IID, ppProtectedSession: ^rawptr) -> HRESULT,
}


IResource2_UUID :: "BE36EC3B-EA85-4AEB-A45A-E9D76404A495"
IResource2 :: struct #raw_union {
	#subtype id3d12resource1: IResource1,
	using id3d12resource2_vtable: ^IResource2_VTable,
}
IResource2_VTable :: struct {
	using id3d12resource1_vtable: IResource1_VTable,
	GetDesc1: proc "stdcall" (this: ^IResource2) -> RESOURCE_DESC1,
}


IHeap1_UUID :: "572F7389-2168-49E3-9693-D6DF5871BF6D"
IHeap1 :: struct #raw_union {
	#subtype id3d12heap: IHeap,
	using id3d12heap1_vtable: ^IHeap1_VTable,
}
IHeap1_VTable :: struct {
	using id3d12heap_vtable: IHeap_VTable,
	GetProtectedResourceSession: proc "stdcall" (this: ^IHeap1, riid: ^IID, ppProtectedSession: ^rawptr) -> HRESULT,
}


IGraphicsCommandList3_UUID :: "6FDA83A7-B84C-4E38-9AC8-C7BD22016B3D"
IGraphicsCommandList3 :: struct #raw_union {
	#subtype id3d12graphicscommandlist2: IGraphicsCommandList2,
	using id3d12graphicscommandlist3_vtable: ^IGraphicsCommandList3_VTable,
}
IGraphicsCommandList3_VTable :: struct {
	using id3d12graphicscommandlist2_vtable: IGraphicsCommandList2_VTable,
	SetProtectedResourceSession: proc "stdcall" (this: ^IGraphicsCommandList3, pProtectedResourceSession: ^IProtectedResourceSession),
}

RENDER_PASS_BEGINNING_ACCESS_TYPE :: enum i32 {
	DISCARD   = 0,
	PRESERVE  = 1,
	CLEAR     = 2,
	NO_ACCESS = 3,
}

RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS :: struct {
	ClearValue: CLEAR_VALUE,
}

RENDER_PASS_BEGINNING_ACCESS :: struct {
	Type: RENDER_PASS_BEGINNING_ACCESS_TYPE,
	using _: struct #raw_union {
		Clear: RENDER_PASS_BEGINNING_ACCESS_CLEAR_PARAMETERS,
	},
}

RENDER_PASS_ENDING_ACCESS_TYPE :: enum i32 {
	DISCARD   = 0,
	PRESERVE  = 1,
	RESOLVE   = 2,
	NO_ACCESS = 3,
}

RENDER_PASS_ENDING_ACCESS_RESOLVE_SUBRESOURCE_PARAMETERS :: struct {
	SrcSubresource: u32,
	DstSubresource: u32,
	DstX:           u32,
	DstY:           u32,
	SrcRect:        RECT,
}

RENDER_PASS_ENDING_ACCESS_RESOLVE_PARAMETERS :: struct {
	pSrcResource:           ^IResource,
	pDstResource:           ^IResource,
	SubresourceCount:       u32,
	pSubresourceParameters: ^RENDER_PASS_ENDING_ACCESS_RESOLVE_SUBRESOURCE_PARAMETERS,
	Format:                 dxgi.FORMAT,
	ResolveMode:            RESOLVE_MODE,
	PreserveResolveSource:  BOOL,
}

RENDER_PASS_ENDING_ACCESS :: struct {
	Type: RENDER_PASS_ENDING_ACCESS_TYPE,
	using _: struct #raw_union {
		Resolve: RENDER_PASS_ENDING_ACCESS_RESOLVE_PARAMETERS,
	},
}

RENDER_PASS_RENDER_TARGET_DESC :: struct {
	cpuDescriptor:   CPU_DESCRIPTOR_HANDLE,
	BeginningAccess: RENDER_PASS_BEGINNING_ACCESS,
	EndingAccess:    RENDER_PASS_ENDING_ACCESS,
}

RENDER_PASS_DEPTH_STENCIL_DESC :: struct {
	cpuDescriptor:          CPU_DESCRIPTOR_HANDLE,
	DepthBeginningAccess:   RENDER_PASS_BEGINNING_ACCESS,
	StencilBeginningAccess: RENDER_PASS_BEGINNING_ACCESS,
	DepthEndingAccess:      RENDER_PASS_ENDING_ACCESS,
	StencilEndingAccess:    RENDER_PASS_ENDING_ACCESS,
}

RENDER_PASS_FLAGS :: enum u32 { // TODO: make bit_set
	NONE             = 0x0,
	ALLOW_UAV_WRITES = 0x1,
	SUSPENDING_PASS  = 0x2,
	RESUMING_PASS    = 0x4,
}


IMetaCommand_UUID :: "DBB84C27-36CE-4FC9-B801-F048C46AC570"
IMetaCommand :: struct #raw_union {
	#subtype id3d12pageable: IPageable,
	using id3d12metacommand_vtable: ^IMetaCommand_VTable,
}
IMetaCommand_VTable :: struct {
	using id3d12devicechild_vtable: IDeviceChild_VTable,
	GetRequiredParameterResourceSize: proc "stdcall" (this: ^IMetaCommand, Stage: META_COMMAND_PARAMETER_STAGE, ParameterIndex: u32) -> u64,
}

DISPATCH_RAYS_DESC :: struct {
	RayGenerationShaderRecord: GPU_VIRTUAL_ADDRESS_RANGE,
	MissShaderTable:           GPU_VIRTUAL_ADDRESS_RANGE_AND_STRIDE,
	HitGroupTable:             GPU_VIRTUAL_ADDRESS_RANGE_AND_STRIDE,
	CallableShaderTable:       GPU_VIRTUAL_ADDRESS_RANGE_AND_STRIDE,
	Width:                     u32,
	Height:                    u32,
	Depth:                     u32,
}


IGraphicsCommandList4_UUID :: "8754318e-d3a9-4541-98cf-645b50dc4874"
IGraphicsCommandList4 :: struct #raw_union {
	#subtype id3d12graphicscommandlist3: IGraphicsCommandList3,
	using id3d12graphicscommandlist4_vtable: ^IGraphicsCommandList4_VTable,
}
IGraphicsCommandList4_VTable :: struct {
	using id3d12graphicscommandlist3_vtable: IGraphicsCommandList3_VTable,
	BeginRenderPass:                                  proc "stdcall" (this: ^IGraphicsCommandList4, NumRenderTargets: u32, pRenderTargets: ^RENDER_PASS_RENDER_TARGET_DESC, pDepthStencil: ^RENDER_PASS_DEPTH_STENCIL_DESC, Flags: RENDER_PASS_FLAGS),
	EndRenderPass:                                    proc "stdcall" (this: ^IGraphicsCommandList4),
	InitializeMetaCommand:                            proc "stdcall" (this: ^IGraphicsCommandList4, pMetaCommand: ^IMetaCommand, pInitializationParametersData: rawptr, InitializationParametersDataSizeInBytes: SIZE_T),
	ExecuteMetaCommand:                               proc "stdcall" (this: ^IGraphicsCommandList4, pMetaCommand: ^IMetaCommand, pExecutionParametersData: rawptr, ExecutionParametersDataSizeInBytes: SIZE_T),
	BuildRaytracingAccelerationStructure:             proc "stdcall" (this: ^IGraphicsCommandList4, pDesc: ^BUILD_RAYTRACING_ACCELERATION_STRUCTURE_DESC, NumPostbuildInfoDescs: u32, pPostbuildInfoDescs: ^RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_DESC),
	EmitRaytracingAccelerationStructurePostbuildInfo: proc "stdcall" (this: ^IGraphicsCommandList4, pDesc: ^RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_DESC, NumSourceAccelerationStructures: u32, pSourceAccelerationStructureData: ^GPU_VIRTUAL_ADDRESS),
	CopyRaytracingAccelerationStructure:              proc "stdcall" (this: ^IGraphicsCommandList4, DestAccelerationStructureData: GPU_VIRTUAL_ADDRESS, SourceAccelerationStructureData: GPU_VIRTUAL_ADDRESS, Mode: RAYTRACING_ACCELERATION_STRUCTURE_COPY_MODE),
	SetPipelineState1:                                proc "stdcall" (this: ^IGraphicsCommandList4, pStateObject: ^IStateObject),
	DispatchRays:                                     proc "stdcall" (this: ^IGraphicsCommandList4, pDesc: ^DISPATCH_RAYS_DESC),
}


ITools_UUID :: "7071e1f0-e84b-4b33-974f-12fa49de65c5"
ITools :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12tools_vtable: ^ITools_VTable,
}
ITools_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	EnableShaderInstrumentation: proc "stdcall" (this: ^ITools, bEnable: BOOL),
	ShaderInstrumentationEnabled: proc "stdcall" (this: ^ITools) -> BOOL,
}

SUBRESOURCE_DATA :: struct {
	pData:      rawptr,
	RowPitch:   i64,
	SlicePitch: i64,
}

MEMCPY_DEST :: struct {
	pData:      rawptr,
	RowPitch:   SIZE_T,
	SlicePitch: SIZE_T,
}


IDebug_UUID :: "344488b7-6846-474b-b989-f027448245e0"
IDebug :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debug_vtable: ^IDebug_VTable,
}
IDebug_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	EnableDebugLayer: proc "stdcall" (this: ^IDebug),
}

GPU_BASED_VALIDATION_FLAGS :: enum u32 { // TODO: make bit_set
	NONE                   = 0x0,
	DISABLE_STATE_TRACKING = 0x1,
}


IDebug1_UUID :: "affaa4ca-63fe-4d8e-b8ad-159000af4304"
IDebug1 :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debug1_vtable: ^IDebug1_VTable,
}
IDebug1_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	EnableDebugLayer:                            proc "stdcall" (this: ^IDebug1),
	SetEnableGPUBasedValidation:                 proc "stdcall" (this: ^IDebug1, Enable: BOOL),
	SetEnableSynchronizedCommandQueueValidation: proc "stdcall" (this: ^IDebug1, Enable: BOOL),
}


IDebug2_UUID :: "93a665c4-a3b2-4e5d-b692-a26ae14e3374"
IDebug2 :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debug2_vtable: ^IDebug2_VTable,
}
IDebug2_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetGPUBasedValidationFlags: proc "stdcall" (this: ^IDebug2, Flags: GPU_BASED_VALIDATION_FLAGS),
}


IDebug3_UUID :: "5cf4e58f-f671-4ff1-a542-3686e3d153d1"
IDebug3 :: struct #raw_union {
	#subtype id3d12debug: IDebug,
	using id3d12debug3_vtable: ^IDebug3_VTable,
}
IDebug3_VTable :: struct {
	using id3d12debug_vtable: IDebug_VTable,
	SetEnableGPUBasedValidation:                 proc "stdcall" (this: ^IDebug3, Enable: BOOL),
	SetEnableSynchronizedCommandQueueValidation: proc "stdcall" (this: ^IDebug3, Enable: BOOL),
	SetGPUBasedValidationFlags:                  proc "stdcall" (this: ^IDebug3, Flags: GPU_BASED_VALIDATION_FLAGS),
}

RLDO_FLAGS :: enum u32 { // TODO: make bit_set
	NONE            = 0x0,
	SUMMARY         = 0x1,
	DETAIL          = 0x2,
	IGNORE_INTERNAL = 0x4,
}

DEBUG_DEVICE_PARAMETER_TYPE :: enum i32 {
	FEATURE_FLAGS                   = 0,
	GPU_BASED_VALIDATION_SETTINGS   = 1,
	GPU_SLOWDOWN_PERFORMANCE_FACTOR = 2,
}

DEBUG_FEATURE :: enum i32 { // TODO: make bit_set
	NONE                                   = 0,
	ALLOW_BEHAVIOR_CHANGING_DEBUG_AIDS     = 1,
	CONSERVATIVE_RESOURCE_STATE_TRACKING   = 2,
	DISABLE_VIRTUALIZED_BUNDLES_VALIDATION = 4,
	EMULATE_WINDOWS7                       = 8,
}

GPU_BASED_VALIDATION_SHADER_PATCH_MODE :: enum i32 {
	NONE                                              = 0,
	STATE_TRACKING_ONLY                               = 1,
	UNGUARDED_VALIDATION                              = 2,
	GUARDED_VALIDATION                                = 3,
	NUM_GPU_BASED_VALIDATION_SHADER_PATCH_MODES = 4,
}

GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS :: enum u32 { // TODO: make bit_set
	GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_NONE                                           = 0x0,
	GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_TRACKING_ONLY_SHADERS        = 0x1,
	GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_UNGUARDED_VALIDATION_SHADERS = 0x2,
	GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAG_FRONT_LOAD_CREATE_GUARDED_VALIDATION_SHADERS   = 0x4,
	VALID_MASK                                                                                           = 0x7,
}

DEBUG_DEVICE_GPU_BASED_VALIDATION_SETTINGS :: struct {
	MaxMessagesPerCommandList: u32,
	DefaultShaderPatchMode:    GPU_BASED_VALIDATION_SHADER_PATCH_MODE,
	PipelineStateCreateFlags:  GPU_BASED_VALIDATION_PIPELINE_STATE_CREATE_FLAGS,
}

DEBUG_DEVICE_GPU_SLOWDOWN_PERFORMANCE_FACTOR :: struct {
	SlowdownFactor: f32,
}


IDebugDevice1_UUID :: "a9b71770-d099-4a65-a698-3dee10020f88"
IDebugDevice1 :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debugdevice1_vtable: ^IDebugDevice1_VTable,
}
IDebugDevice1_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetDebugParameter:       proc "stdcall" (this: ^IDebugDevice1, Type: DEBUG_DEVICE_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
	GetDebugParameter:       proc "stdcall" (this: ^IDebugDevice1, Type: DEBUG_DEVICE_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
	ReportLiveDeviceObjects: proc "stdcall" (this: ^IDebugDevice1, Flags: RLDO_FLAGS) -> HRESULT,
}


IDebugDevice_UUID :: "3febd6dd-4973-4787-8194-e45f9e28923e"
IDebugDevice :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debugdevice_vtable: ^IDebugDevice_VTable,
}
IDebugDevice_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetFeatureMask:          proc "stdcall" (this: ^IDebugDevice, Mask: DEBUG_FEATURE) -> HRESULT,
	GetFeatureMask:          proc "stdcall" (this: ^IDebugDevice) -> DEBUG_FEATURE,
	ReportLiveDeviceObjects: proc "stdcall" (this: ^IDebugDevice, Flags: RLDO_FLAGS) -> HRESULT,
}


IDebugDevice2_UUID :: "60eccbc1-378d-4df1-894c-f8ac5ce4d7dd"
IDebugDevice2 :: struct #raw_union {
	#subtype id3d12debugdevice: IDebugDevice,
	using id3d12debugdevice2_vtable: ^IDebugDevice2_VTable,
}
IDebugDevice2_VTable :: struct {
	using id3d12debugdevice_vtable: IDebugDevice_VTable,
	SetDebugParameter: proc "stdcall" (this: ^IDebugDevice2, Type: DEBUG_DEVICE_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
	GetDebugParameter: proc "stdcall" (this: ^IDebugDevice2, Type: DEBUG_DEVICE_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
}



IDebugCommandQueue_UUID :: "09e0bf36-54ac-484f-8847-4baeeab6053a"
IDebugCommandQueue :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debugcommandqueue_vtable: ^IDebugCommandQueue_VTable,
}
IDebugCommandQueue_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	AssertResourceState: proc "stdcall" (this: ^IDebugCommandQueue, pResource: ^IResource, Subresource: u32, State: u32) -> BOOL,
}

DEBUG_COMMAND_LIST_PARAMETER_TYPE :: enum i32 {
	DEBUG_COMMAND_LIST_PARAMETER_GPU_BASED_VALIDATION_SETTINGS = 0,
}

DEBUG_COMMAND_LIST_GPU_BASED_VALIDATION_SETTINGS :: struct {
	ShaderPatchMode: GPU_BASED_VALIDATION_SHADER_PATCH_MODE,
}


IDebugCommandList1_UUID :: "102ca951-311b-4b01-b11f-ecb83e061b37"
IDebugCommandList1 :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debugcommandlist1_vtable: ^IDebugCommandList1_VTable,
}
IDebugCommandList1_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	AssertResourceState: proc "stdcall" (this: ^IDebugCommandList1, pResource: ^IResource, Subresource: u32, State: u32) -> BOOL,
	SetDebugParameter:   proc "stdcall" (this: ^IDebugCommandList1, Type: DEBUG_COMMAND_LIST_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
	GetDebugParameter:   proc "stdcall" (this: ^IDebugCommandList1, Type: DEBUG_COMMAND_LIST_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
}


IDebugCommandList_UUID :: "09e0bf36-54ac-484f-8847-4baeeab6053f"
IDebugCommandList :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12debugcommandlist_vtable: ^IDebugCommandList_VTable,
}
IDebugCommandList_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	AssertResourceState: proc "stdcall" (this: ^IDebugCommandList, pResource: ^IResource, Subresource: u32, State: u32) -> BOOL,
	SetFeatureMask: proc "stdcall" (this: ^IDebugCommandList, Mask: DEBUG_FEATURE) -> HRESULT,
	GetFeatureMask: proc "stdcall" (this: ^IDebugCommandList) -> DEBUG_FEATURE,
}


IDebugCommandList2_UUID :: "aeb575cf-4e06-48be-ba3b-c450fc96652e"
IDebugCommandList2 :: struct #raw_union {
	#subtype id3d12debugcommandlist: IDebugCommandList,
	using id3d12debugcommandlist2_vtable: ^IDebugCommandList2_VTable,
}
IDebugCommandList2_VTable :: struct {
	using id3d12debugcommandlist_vtable: IDebugCommandList_VTable,
	SetDebugParameter: proc "stdcall" (this: ^IDebugCommandList2, Type: DEBUG_COMMAND_LIST_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
	GetDebugParameter: proc "stdcall" (this: ^IDebugCommandList2, Type: DEBUG_COMMAND_LIST_PARAMETER_TYPE, pData: rawptr, DataSize: u32) -> HRESULT,
}


ISharingContract_UUID :: "0adf7d52-929c-4e61-addb-ffed30de66ef"
ISharingContract :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12sharingcontract_vtable: ^ISharingContract_VTable,
}
ISharingContract_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	Present:             proc "stdcall" (this: ^ISharingContract, pResource: ^IResource, Subresource: u32, window: HWND),
	SharedFenceSignal:   proc "stdcall" (this: ^ISharingContract, pFence: ^IFence, FenceValue: u64),
	BeginCapturableWork: proc "stdcall" (this: ^ISharingContract, guid: ^GUID),
	EndCapturableWork:   proc "stdcall" (this: ^ISharingContract, guid: ^GUID),
}

MESSAGE_CATEGORY :: enum i32 {
	APPLICATION_DEFINED   = 0,
	MISCELLANEOUS         = 1,
	INITIALIZATION        = 2,
	CLEANUP               = 3,
	COMPILATION           = 4,
	STATE_CREATION        = 5,
	STATE_SETTING         = 6,
	STATE_GETTING         = 7,
	RESOURCE_MANIPULATION = 8,
	EXECUTION             = 9,
	SHADER                = 10,
}

MESSAGE_SEVERITY :: enum i32 {
	CORRUPTION = 0,
	ERROR      = 1,
	WARNING    = 2,
	INFO       = 3,
	MESSAGE    = 4,
}

MESSAGE_ID :: enum i32 {
	UNKNOWN                                                                                       = 0,
	STRING_FROM_APPLICATION                                                                       = 1,
	CORRUPTED_THIS                                                                                = 2,
	CORRUPTED_PARAMETER1                                                                          = 3,
	CORRUPTED_PARAMETER2                                                                          = 4,
	CORRUPTED_PARAMETER3                                                                          = 5,
	CORRUPTED_PARAMETER4                                                                          = 6,
	CORRUPTED_PARAMETER5                                                                          = 7,
	CORRUPTED_PARAMETER6                                                                          = 8,
	CORRUPTED_PARAMETER7                                                                          = 9,
	CORRUPTED_PARAMETER8                                                                          = 10,
	CORRUPTED_PARAMETER9                                                                          = 11,
	CORRUPTED_PARAMETER10                                                                         = 12,
	CORRUPTED_PARAMETER11                                                                         = 13,
	CORRUPTED_PARAMETER12                                                                         = 14,
	CORRUPTED_PARAMETER13                                                                         = 15,
	CORRUPTED_PARAMETER14                                                                         = 16,
	CORRUPTED_PARAMETER15                                                                         = 17,
	CORRUPTED_MULTITHREADING                                                                      = 18,
	MESSAGE_REPORTING_OUTOFMEMORY                                                                 = 19,
	GETPRIVATEDATA_MOREDATA                                                                       = 20,
	SETPRIVATEDATA_INVALIDFREEDATA                                                                = 21,
	SETPRIVATEDATA_CHANGINGPARAMS                                                                 = 24,
	SETPRIVATEDATA_OUTOFMEMORY                                                                    = 25,
	CREATESHADERRESOURCEVIEW_UNRECOGNIZEDFORMAT                                                   = 26,
	CREATESHADERRESOURCEVIEW_INVALIDDESC                                                          = 27,
	CREATESHADERRESOURCEVIEW_INVALIDFORMAT                                                        = 28,
	CREATESHADERRESOURCEVIEW_INVALIDVIDEOPLANESLICE                                               = 29,
	CREATESHADERRESOURCEVIEW_INVALIDPLANESLICE                                                    = 30,
	CREATESHADERRESOURCEVIEW_INVALIDDIMENSIONS                                                    = 31,
	CREATESHADERRESOURCEVIEW_INVALIDRESOURCE                                                      = 32,
	CREATERENDERTARGETVIEW_UNRECOGNIZEDFORMAT                                                     = 35,
	CREATERENDERTARGETVIEW_UNSUPPORTEDFORMAT                                                      = 36,
	CREATERENDERTARGETVIEW_INVALIDDESC                                                            = 37,
	CREATERENDERTARGETVIEW_INVALIDFORMAT                                                          = 38,
	CREATERENDERTARGETVIEW_INVALIDVIDEOPLANESLICE                                                 = 39,
	CREATERENDERTARGETVIEW_INVALIDPLANESLICE                                                      = 40,
	CREATERENDERTARGETVIEW_INVALIDDIMENSIONS                                                      = 41,
	CREATERENDERTARGETVIEW_INVALIDRESOURCE                                                        = 42,
	CREATEDEPTHSTENCILVIEW_UNRECOGNIZEDFORMAT                                                     = 45,
	CREATEDEPTHSTENCILVIEW_INVALIDDESC                                                            = 46,
	CREATEDEPTHSTENCILVIEW_INVALIDFORMAT                                                          = 47,
	CREATEDEPTHSTENCILVIEW_INVALIDDIMENSIONS                                                      = 48,
	CREATEDEPTHSTENCILVIEW_INVALIDRESOURCE                                                        = 49,
	CREATEINPUTLAYOUT_OUTOFMEMORY                                                                 = 52,
	CREATEINPUTLAYOUT_TOOMANYELEMENTS                                                             = 53,
	CREATEINPUTLAYOUT_INVALIDFORMAT                                                               = 54,
	CREATEINPUTLAYOUT_INCOMPATIBLEFORMAT                                                          = 55,
	CREATEINPUTLAYOUT_INVALIDSLOT                                                                 = 56,
	CREATEINPUTLAYOUT_INVALIDINPUTSLOTCLASS                                                       = 57,
	CREATEINPUTLAYOUT_STEPRATESLOTCLASSMISMATCH                                                   = 58,
	CREATEINPUTLAYOUT_INVALIDSLOTCLASSCHANGE                                                      = 59,
	CREATEINPUTLAYOUT_INVALIDSTEPRATECHANGE                                                       = 60,
	CREATEINPUTLAYOUT_INVALIDALIGNMENT                                                            = 61,
	CREATEINPUTLAYOUT_DUPLICATESEMANTIC                                                           = 62,
	CREATEINPUTLAYOUT_UNPARSEABLEINPUTSIGNATURE                                                   = 63,
	CREATEINPUTLAYOUT_NULLSEMANTIC                                                                = 64,
	CREATEINPUTLAYOUT_MISSINGELEMENT                                                              = 65,
	CREATEVERTEXSHADER_OUTOFMEMORY                                                                = 66,
	CREATEVERTEXSHADER_INVALIDSHADERBYTECODE                                                      = 67,
	CREATEVERTEXSHADER_INVALIDSHADERTYPE                                                          = 68,
	CREATEGEOMETRYSHADER_OUTOFMEMORY                                                              = 69,
	CREATEGEOMETRYSHADER_INVALIDSHADERBYTECODE                                                    = 70,
	CREATEGEOMETRYSHADER_INVALIDSHADERTYPE                                                        = 71,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_OUTOFMEMORY                                              = 72,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDSHADERBYTECODE                                    = 73,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDSHADERTYPE                                        = 74,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDNUMENTRIES                                        = 75,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_OUTPUTSTREAMSTRIDEUNUSED                                 = 76,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_OUTPUTSLOT0EXPECTED                                      = 79,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDOUTPUTSLOT                                        = 80,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_ONLYONEELEMENTPERSLOT                                    = 81,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDCOMPONENTCOUNT                                    = 82,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDSTARTCOMPONENTANDCOMPONENTCOUNT                   = 83,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDGAPDEFINITION                                     = 84,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_REPEATEDOUTPUT                                           = 85,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDOUTPUTSTREAMSTRIDE                                = 86,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_MISSINGSEMANTIC                                          = 87,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_MASKMISMATCH                                             = 88,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_CANTHAVEONLYGAPS                                         = 89,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_DECLTOOCOMPLEX                                           = 90,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_MISSINGOUTPUTSIGNATURE                                   = 91,
	CREATEPIXELSHADER_OUTOFMEMORY                                                                 = 92,
	CREATEPIXELSHADER_INVALIDSHADERBYTECODE                                                       = 93,
	CREATEPIXELSHADER_INVALIDSHADERTYPE                                                           = 94,
	CREATERASTERIZERSTATE_INVALIDFILLMODE                                                         = 95,
	CREATERASTERIZERSTATE_INVALIDCULLMODE                                                         = 96,
	CREATERASTERIZERSTATE_INVALIDDEPTHBIASCLAMP                                                   = 97,
	CREATERASTERIZERSTATE_INVALIDSLOPESCALEDDEPTHBIAS                                             = 98,
	CREATEDEPTHSTENCILSTATE_INVALIDDEPTHWRITEMASK                                                 = 100,
	CREATEDEPTHSTENCILSTATE_INVALIDDEPTHFUNC                                                      = 101,
	CREATEDEPTHSTENCILSTATE_INVALIDFRONTFACESTENCILFAILOP                                         = 102,
	CREATEDEPTHSTENCILSTATE_INVALIDFRONTFACESTENCILZFAILOP                                        = 103,
	CREATEDEPTHSTENCILSTATE_INVALIDFRONTFACESTENCILPASSOP                                         = 104,
	CREATEDEPTHSTENCILSTATE_INVALIDFRONTFACESTENCILFUNC                                           = 105,
	CREATEDEPTHSTENCILSTATE_INVALIDBACKFACESTENCILFAILOP                                          = 106,
	CREATEDEPTHSTENCILSTATE_INVALIDBACKFACESTENCILZFAILOP                                         = 107,
	CREATEDEPTHSTENCILSTATE_INVALIDBACKFACESTENCILPASSOP                                          = 108,
	CREATEDEPTHSTENCILSTATE_INVALIDBACKFACESTENCILFUNC                                            = 109,
	CREATEBLENDSTATE_INVALIDSRCBLEND                                                              = 111,
	CREATEBLENDSTATE_INVALIDDESTBLEND                                                             = 112,
	CREATEBLENDSTATE_INVALIDBLENDOP                                                               = 113,
	CREATEBLENDSTATE_INVALIDSRCBLENDALPHA                                                         = 114,
	CREATEBLENDSTATE_INVALIDDESTBLENDALPHA                                                        = 115,
	CREATEBLENDSTATE_INVALIDBLENDOPALPHA                                                          = 116,
	CREATEBLENDSTATE_INVALIDRENDERTARGETWRITEMASK                                                 = 117,
	CLEARDEPTHSTENCILVIEW_INVALID                                                                 = 135,
	COMMAND_LIST_DRAW_ROOT_SIGNATURE_NOT_SET                                                      = 200,
	COMMAND_LIST_DRAW_ROOT_SIGNATURE_MISMATCH                                                     = 201,
	COMMAND_LIST_DRAW_VERTEX_BUFFER_NOT_SET                                                       = 202,
	COMMAND_LIST_DRAW_VERTEX_BUFFER_STRIDE_TOO_SMALL                                              = 209,
	COMMAND_LIST_DRAW_VERTEX_BUFFER_TOO_SMALL                                                     = 210,
	COMMAND_LIST_DRAW_INDEX_BUFFER_NOT_SET                                                        = 211,
	COMMAND_LIST_DRAW_INDEX_BUFFER_FORMAT_INVALID                                                 = 212,
	COMMAND_LIST_DRAW_INDEX_BUFFER_TOO_SMALL                                                      = 213,
	COMMAND_LIST_DRAW_INVALID_PRIMITIVETOPOLOGY                                                   = 219,
	COMMAND_LIST_DRAW_VERTEX_STRIDE_UNALIGNED                                                     = 221,
	COMMAND_LIST_DRAW_INDEX_OFFSET_UNALIGNED                                                      = 222,
	DEVICE_REMOVAL_PROCESS_AT_FAULT                                                               = 232,
	DEVICE_REMOVAL_PROCESS_POSSIBLY_AT_FAULT                                                      = 233,
	DEVICE_REMOVAL_PROCESS_NOT_AT_FAULT                                                           = 234,
	CREATEINPUTLAYOUT_TRAILING_DIGIT_IN_SEMANTIC                                                  = 239,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_TRAILING_DIGIT_IN_SEMANTIC                               = 240,
	CREATEINPUTLAYOUT_TYPE_MISMATCH                                                               = 245,
	CREATEINPUTLAYOUT_EMPTY_LAYOUT                                                                = 253,
	LIVE_OBJECT_SUMMARY                                                                           = 255,
	LIVE_DEVICE                                                                                   = 274,
	LIVE_SWAPCHAIN                                                                                = 275,
	CREATEDEPTHSTENCILVIEW_INVALIDFLAGS                                                           = 276,
	CREATEVERTEXSHADER_INVALIDCLASSLINKAGE                                                        = 277,
	CREATEGEOMETRYSHADER_INVALIDCLASSLINKAGE                                                      = 278,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDSTREAMTORASTERIZER                                = 280,
	CREATEPIXELSHADER_INVALIDCLASSLINKAGE                                                         = 283,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDSTREAM                                            = 284,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_UNEXPECTEDENTRIES                                        = 285,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_UNEXPECTEDSTRIDES                                        = 286,
	CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_INVALIDNUMSTRIDES                                        = 287,
	CREATEHULLSHADER_OUTOFMEMORY                                                                  = 289,
	CREATEHULLSHADER_INVALIDSHADERBYTECODE                                                        = 290,
	CREATEHULLSHADER_INVALIDSHADERTYPE                                                            = 291,
	CREATEHULLSHADER_INVALIDCLASSLINKAGE                                                          = 292,
	CREATEDOMAINSHADER_OUTOFMEMORY                                                                = 294,
	CREATEDOMAINSHADER_INVALIDSHADERBYTECODE                                                      = 295,
	CREATEDOMAINSHADER_INVALIDSHADERTYPE                                                          = 296,
	CREATEDOMAINSHADER_INVALIDCLASSLINKAGE                                                        = 297,
	RESOURCE_UNMAP_NOTMAPPED                                                                      = 310,
	DEVICE_CHECKFEATURESUPPORT_MISMATCHED_DATA_SIZE                                               = 318,
	CREATECOMPUTESHADER_OUTOFMEMORY                                                               = 321,
	CREATECOMPUTESHADER_INVALIDSHADERBYTECODE                                                     = 322,
	CREATECOMPUTESHADER_INVALIDCLASSLINKAGE                                                       = 323,
	DEVICE_CREATEVERTEXSHADER_DOUBLEFLOATOPSNOTSUPPORTED                                          = 331,
	DEVICE_CREATEHULLSHADER_DOUBLEFLOATOPSNOTSUPPORTED                                            = 332,
	DEVICE_CREATEDOMAINSHADER_DOUBLEFLOATOPSNOTSUPPORTED                                          = 333,
	DEVICE_CREATEGEOMETRYSHADER_DOUBLEFLOATOPSNOTSUPPORTED                                        = 334,
	DEVICE_CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_DOUBLEFLOATOPSNOTSUPPORTED                        = 335,
	DEVICE_CREATEPIXELSHADER_DOUBLEFLOATOPSNOTSUPPORTED                                           = 336,
	DEVICE_CREATECOMPUTESHADER_DOUBLEFLOATOPSNOTSUPPORTED                                         = 337,
	CREATEUNORDEREDACCESSVIEW_INVALIDRESOURCE                                                     = 340,
	CREATEUNORDEREDACCESSVIEW_INVALIDDESC                                                         = 341,
	CREATEUNORDEREDACCESSVIEW_INVALIDFORMAT                                                       = 342,
	CREATEUNORDEREDACCESSVIEW_INVALIDVIDEOPLANESLICE                                              = 343,
	CREATEUNORDEREDACCESSVIEW_INVALIDPLANESLICE                                                   = 344,
	CREATEUNORDEREDACCESSVIEW_INVALIDDIMENSIONS                                                   = 345,
	CREATEUNORDEREDACCESSVIEW_UNRECOGNIZEDFORMAT                                                  = 346,
	CREATEUNORDEREDACCESSVIEW_INVALIDFLAGS                                                        = 354,
	CREATERASTERIZERSTATE_INVALIDFORCEDSAMPLECOUNT                                                = 401,
	CREATEBLENDSTATE_INVALIDLOGICOPS                                                              = 403,
	DEVICE_CREATEVERTEXSHADER_DOUBLEEXTENSIONSNOTSUPPORTED                                        = 410,
	DEVICE_CREATEHULLSHADER_DOUBLEEXTENSIONSNOTSUPPORTED                                          = 412,
	DEVICE_CREATEDOMAINSHADER_DOUBLEEXTENSIONSNOTSUPPORTED                                        = 414,
	DEVICE_CREATEGEOMETRYSHADER_DOUBLEEXTENSIONSNOTSUPPORTED                                      = 416,
	DEVICE_CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_DOUBLEEXTENSIONSNOTSUPPORTED                      = 418,
	DEVICE_CREATEPIXELSHADER_DOUBLEEXTENSIONSNOTSUPPORTED                                         = 420,
	DEVICE_CREATECOMPUTESHADER_DOUBLEEXTENSIONSNOTSUPPORTED                                       = 422,
	DEVICE_CREATEVERTEXSHADER_UAVSNOTSUPPORTED                                                    = 425,
	DEVICE_CREATEHULLSHADER_UAVSNOTSUPPORTED                                                      = 426,
	DEVICE_CREATEDOMAINSHADER_UAVSNOTSUPPORTED                                                    = 427,
	DEVICE_CREATEGEOMETRYSHADER_UAVSNOTSUPPORTED                                                  = 428,
	DEVICE_CREATEGEOMETRYSHADERWITHSTREAMOUTPUT_UAVSNOTSUPPORTED                                  = 429,
	DEVICE_CREATEPIXELSHADER_UAVSNOTSUPPORTED                                                     = 430,
	DEVICE_CREATECOMPUTESHADER_UAVSNOTSUPPORTED                                                   = 431,
	DEVICE_CLEARVIEW_INVALIDSOURCERECT                                                            = 447,
	DEVICE_CLEARVIEW_EMPTYRECT                                                                    = 448,
	UPDATETILEMAPPINGS_INVALID_PARAMETER                                                          = 493,
	COPYTILEMAPPINGS_INVALID_PARAMETER                                                            = 494,
	CREATEDEVICE_INVALIDARGS                                                                      = 506,
	CREATEDEVICE_WARNING                                                                          = 507,
	RESOURCE_BARRIER_INVALID_TYPE                                                                 = 519,
	RESOURCE_BARRIER_NULL_POINTER                                                                 = 520,
	RESOURCE_BARRIER_INVALID_SUBRESOURCE                                                          = 521,
	RESOURCE_BARRIER_RESERVED_BITS                                                                = 522,
	RESOURCE_BARRIER_MISSING_BIND_FLAGS                                                           = 523,
	RESOURCE_BARRIER_MISMATCHING_MISC_FLAGS                                                       = 524,
	RESOURCE_BARRIER_MATCHING_STATES                                                              = 525,
	RESOURCE_BARRIER_INVALID_COMBINATION                                                          = 526,
	RESOURCE_BARRIER_BEFORE_AFTER_MISMATCH                                                        = 527,
	RESOURCE_BARRIER_INVALID_RESOURCE                                                             = 528,
	RESOURCE_BARRIER_SAMPLE_COUNT                                                                 = 529,
	RESOURCE_BARRIER_INVALID_FLAGS                                                                = 530,
	RESOURCE_BARRIER_INVALID_COMBINED_FLAGS                                                       = 531,
	RESOURCE_BARRIER_INVALID_FLAGS_FOR_FORMAT                                                     = 532,
	RESOURCE_BARRIER_INVALID_SPLIT_BARRIER                                                        = 533,
	RESOURCE_BARRIER_UNMATCHED_END                                                                = 534,
	RESOURCE_BARRIER_UNMATCHED_BEGIN                                                              = 535,
	RESOURCE_BARRIER_INVALID_FLAG                                                                 = 536,
	RESOURCE_BARRIER_INVALID_COMMAND_LIST_TYPE                                                    = 537,
	INVALID_SUBRESOURCE_STATE                                                                     = 538,
	COMMAND_ALLOCATOR_CONTENTION                                                                  = 540,
	COMMAND_ALLOCATOR_RESET                                                                       = 541,
	COMMAND_ALLOCATOR_RESET_BUNDLE                                                                = 542,
	COMMAND_ALLOCATOR_CANNOT_RESET                                                                = 543,
	COMMAND_LIST_OPEN                                                                             = 544,
	INVALID_BUNDLE_API                                                                            = 546,
	COMMAND_LIST_CLOSED                                                                           = 547,
	WRONG_COMMAND_ALLOCATOR_TYPE                                                                  = 549,
	COMMAND_ALLOCATOR_SYNC                                                                        = 552,
	COMMAND_LIST_SYNC                                                                             = 553,
	SET_DESCRIPTOR_HEAP_INVALID                                                                   = 554,
	CREATE_COMMANDQUEUE                                                                           = 557,
	CREATE_COMMANDALLOCATOR                                                                       = 558,
	CREATE_PIPELINESTATE                                                                          = 559,
	CREATE_COMMANDLIST12                                                                          = 560,
	CREATE_RESOURCE                                                                               = 562,
	CREATE_DESCRIPTORHEAP                                                                         = 563,
	CREATE_ROOTSIGNATURE                                                                          = 564,
	CREATE_LIBRARY                                                                                = 565,
	CREATE_HEAP                                                                                   = 566,
	CREATE_MONITOREDFENCE                                                                         = 567,
	CREATE_QUERYHEAP                                                                              = 568,
	CREATE_COMMANDSIGNATURE                                                                       = 569,
	LIVE_COMMANDQUEUE                                                                             = 570,
	LIVE_COMMANDALLOCATOR                                                                         = 571,
	LIVE_PIPELINESTATE                                                                            = 572,
	LIVE_COMMANDLIST12                                                                            = 573,
	LIVE_RESOURCE                                                                                 = 575,
	LIVE_DESCRIPTORHEAP                                                                           = 576,
	LIVE_ROOTSIGNATURE                                                                            = 577,
	LIVE_LIBRARY                                                                                  = 578,
	LIVE_HEAP                                                                                     = 579,
	LIVE_MONITOREDFENCE                                                                           = 580,
	LIVE_QUERYHEAP                                                                                = 581,
	LIVE_COMMANDSIGNATURE                                                                         = 582,
	DESTROY_COMMANDQUEUE                                                                          = 583,
	DESTROY_COMMANDALLOCATOR                                                                      = 584,
	DESTROY_PIPELINESTATE                                                                         = 585,
	DESTROY_COMMANDLIST12                                                                         = 586,
	DESTROY_RESOURCE                                                                              = 588,
	DESTROY_DESCRIPTORHEAP                                                                        = 589,
	DESTROY_ROOTSIGNATURE                                                                         = 590,
	DESTROY_LIBRARY                                                                               = 591,
	DESTROY_HEAP                                                                                  = 592,
	DESTROY_MONITOREDFENCE                                                                        = 593,
	DESTROY_QUERYHEAP                                                                             = 594,
	DESTROY_COMMANDSIGNATURE                                                                      = 595,
	CREATERESOURCE_INVALIDDIMENSIONS                                                              = 597,
	CREATERESOURCE_INVALIDMISCFLAGS                                                               = 599,
	CREATERESOURCE_INVALIDARG_RETURN                                                              = 602,
	CREATERESOURCE_OUTOFMEMORY_RETURN                                                             = 603,
	CREATERESOURCE_INVALIDDESC                                                                    = 604,
	POSSIBLY_INVALID_SUBRESOURCE_STATE                                                            = 607,
	INVALID_USE_OF_NON_RESIDENT_RESOURCE                                                          = 608,
	POSSIBLE_INVALID_USE_OF_NON_RESIDENT_RESOURCE                                                 = 609,
	BUNDLE_PIPELINE_STATE_MISMATCH                                                                = 610,
	PRIMITIVE_TOPOLOGY_MISMATCH_PIPELINE_STATE                                                    = 611,
	RENDER_TARGET_FORMAT_MISMATCH_PIPELINE_STATE                                                  = 613,
	RENDER_TARGET_SAMPLE_DESC_MISMATCH_PIPELINE_STATE                                             = 614,
	DEPTH_STENCIL_FORMAT_MISMATCH_PIPELINE_STATE                                                  = 615,
	DEPTH_STENCIL_SAMPLE_DESC_MISMATCH_PIPELINE_STATE                                             = 616,
	CREATESHADER_INVALIDBYTECODE                                                                  = 622,
	CREATEHEAP_NULLDESC                                                                           = 623,
	CREATEHEAP_INVALIDSIZE                                                                        = 624,
	CREATEHEAP_UNRECOGNIZEDHEAPTYPE                                                               = 625,
	CREATEHEAP_UNRECOGNIZEDCPUPAGEPROPERTIES                                                      = 626,
	CREATEHEAP_UNRECOGNIZEDMEMORYPOOL                                                             = 627,
	CREATEHEAP_INVALIDPROPERTIES                                                                  = 628,
	CREATEHEAP_INVALIDALIGNMENT                                                                   = 629,
	CREATEHEAP_UNRECOGNIZEDMISCFLAGS                                                              = 630,
	CREATEHEAP_INVALIDMISCFLAGS                                                                   = 631,
	CREATEHEAP_INVALIDARG_RETURN                                                                  = 632,
	CREATEHEAP_OUTOFMEMORY_RETURN                                                                 = 633,
	CREATERESOURCEANDHEAP_NULLHEAPPROPERTIES                                                      = 634,
	CREATERESOURCEANDHEAP_UNRECOGNIZEDHEAPTYPE                                                    = 635,
	CREATERESOURCEANDHEAP_UNRECOGNIZEDCPUPAGEPROPERTIES                                           = 636,
	CREATERESOURCEANDHEAP_UNRECOGNIZEDMEMORYPOOL                                                  = 637,
	CREATERESOURCEANDHEAP_INVALIDHEAPPROPERTIES                                                   = 638,
	CREATERESOURCEANDHEAP_UNRECOGNIZEDHEAPMISCFLAGS                                               = 639,
	CREATERESOURCEANDHEAP_INVALIDHEAPMISCFLAGS                                                    = 640,
	CREATERESOURCEANDHEAP_INVALIDARG_RETURN                                                       = 641,
	CREATERESOURCEANDHEAP_OUTOFMEMORY_RETURN                                                      = 642,
	GETCUSTOMHEAPPROPERTIES_UNRECOGNIZEDHEAPTYPE                                                  = 643,
	GETCUSTOMHEAPPROPERTIES_INVALIDHEAPTYPE                                                       = 644,
	CREATE_DESCRIPTOR_HEAP_INVALID_DESC                                                           = 645,
	INVALID_DESCRIPTOR_HANDLE                                                                     = 646,
	CREATERASTERIZERSTATE_INVALID_CONSERVATIVERASTERMODE                                          = 647,
	CREATE_CONSTANT_BUFFER_VIEW_INVALID_RESOURCE                                                  = 649,
	CREATE_CONSTANT_BUFFER_VIEW_INVALID_DESC                                                      = 650,
	CREATE_UNORDEREDACCESS_VIEW_INVALID_COUNTER_USAGE                                             = 652,
	COPY_DESCRIPTORS_INVALID_RANGES                                                               = 653,
	COPY_DESCRIPTORS_WRITE_ONLY_DESCRIPTOR                                                        = 654,
	CREATEGRAPHICSPIPELINESTATE_RTV_FORMAT_NOT_UNKNOWN                                            = 655,
	CREATEGRAPHICSPIPELINESTATE_INVALID_RENDER_TARGET_COUNT                                       = 656,
	CREATEGRAPHICSPIPELINESTATE_VERTEX_SHADER_NOT_SET                                             = 657,
	CREATEGRAPHICSPIPELINESTATE_INPUTLAYOUT_NOT_SET                                               = 658,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_HS_DS_SIGNATURE_MISMATCH                           = 659,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_REGISTERINDEX                                      = 660,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_COMPONENTTYPE                                      = 661,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_REGISTERMASK                                       = 662,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_SYSTEMVALUE                                        = 663,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_NEVERWRITTEN_ALWAYSREADS                           = 664,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_MINPRECISION                                       = 665,
	CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_SEMANTICNAME_NOT_FOUND                             = 666,
	CREATEGRAPHICSPIPELINESTATE_HS_XOR_DS_MISMATCH                                                = 667,
	CREATEGRAPHICSPIPELINESTATE_HULL_SHADER_INPUT_TOPOLOGY_MISMATCH                               = 668,
	CREATEGRAPHICSPIPELINESTATE_HS_DS_CONTROL_POINT_COUNT_MISMATCH                                = 669,
	CREATEGRAPHICSPIPELINESTATE_HS_DS_TESSELLATOR_DOMAIN_MISMATCH                                 = 670,
	CREATEGRAPHICSPIPELINESTATE_INVALID_USE_OF_CENTER_MULTISAMPLE_PATTERN                         = 671,
	CREATEGRAPHICSPIPELINESTATE_INVALID_USE_OF_FORCED_SAMPLE_COUNT                                = 672,
	CREATEGRAPHICSPIPELINESTATE_INVALID_PRIMITIVETOPOLOGY                                         = 673,
	CREATEGRAPHICSPIPELINESTATE_INVALID_SYSTEMVALUE                                               = 674,
	CREATEGRAPHICSPIPELINESTATE_OM_DUAL_SOURCE_BLENDING_CAN_ONLY_HAVE_RENDER_TARGET_0             = 675,
	CREATEGRAPHICSPIPELINESTATE_OM_RENDER_TARGET_DOES_NOT_SUPPORT_BLENDING                        = 676,
	CREATEGRAPHICSPIPELINESTATE_PS_OUTPUT_TYPE_MISMATCH                                           = 677,
	CREATEGRAPHICSPIPELINESTATE_OM_RENDER_TARGET_DOES_NOT_SUPPORT_LOGIC_OPS                       = 678,
	CREATEGRAPHICSPIPELINESTATE_RENDERTARGETVIEW_NOT_SET                                          = 679,
	CREATEGRAPHICSPIPELINESTATE_DEPTHSTENCILVIEW_NOT_SET                                          = 680,
	CREATEGRAPHICSPIPELINESTATE_GS_INPUT_PRIMITIVE_MISMATCH                                       = 681,
	CREATEGRAPHICSPIPELINESTATE_POSITION_NOT_PRESENT                                              = 682,
	CREATEGRAPHICSPIPELINESTATE_MISSING_ROOT_SIGNATURE_FLAGS                                      = 683,
	CREATEGRAPHICSPIPELINESTATE_INVALID_INDEX_BUFFER_PROPERTIES                                   = 684,
	CREATEGRAPHICSPIPELINESTATE_INVALID_SAMPLE_DESC                                               = 685,
	CREATEGRAPHICSPIPELINESTATE_HS_ROOT_SIGNATURE_MISMATCH                                        = 686,
	CREATEGRAPHICSPIPELINESTATE_DS_ROOT_SIGNATURE_MISMATCH                                        = 687,
	CREATEGRAPHICSPIPELINESTATE_VS_ROOT_SIGNATURE_MISMATCH                                        = 688,
	CREATEGRAPHICSPIPELINESTATE_GS_ROOT_SIGNATURE_MISMATCH                                        = 689,
	CREATEGRAPHICSPIPELINESTATE_PS_ROOT_SIGNATURE_MISMATCH                                        = 690,
	CREATEGRAPHICSPIPELINESTATE_MISSING_ROOT_SIGNATURE                                            = 691,
	EXECUTE_BUNDLE_OPEN_BUNDLE                                                                    = 692,
	EXECUTE_BUNDLE_DESCRIPTOR_HEAP_MISMATCH                                                       = 693,
	EXECUTE_BUNDLE_TYPE                                                                           = 694,
	DRAW_EMPTY_SCISSOR_RECTANGLE                                                                  = 695,
	CREATE_ROOT_SIGNATURE_BLOB_NOT_FOUND                                                          = 696,
	CREATE_ROOT_SIGNATURE_DESERIALIZE_FAILED                                                      = 697,
	CREATE_ROOT_SIGNATURE_INVALID_CONFIGURATION                                                   = 698,
	CREATE_ROOT_SIGNATURE_NOT_SUPPORTED_ON_DEVICE                                                 = 699,
	CREATERESOURCEANDHEAP_NULLRESOURCEPROPERTIES                                                  = 700,
	CREATERESOURCEANDHEAP_NULLHEAP                                                                = 701,
	GETRESOURCEALLOCATIONINFO_INVALIDRDESCS                                                       = 702,
	MAKERESIDENT_NULLOBJECTARRAY                                                                  = 703,
	EVICT_NULLOBJECTARRAY                                                                         = 705,
	SET_DESCRIPTOR_TABLE_INVALID                                                                  = 708,
	SET_ROOT_CONSTANT_INVALID                                                                     = 709,
	SET_ROOT_CONSTANT_BUFFER_VIEW_INVALID                                                         = 710,
	SET_ROOT_SHADER_RESOURCE_VIEW_INVALID                                                         = 711,
	SET_ROOT_UNORDERED_ACCESS_VIEW_INVALID                                                        = 712,
	SET_VERTEX_BUFFERS_INVALID_DESC                                                               = 713,
	SET_INDEX_BUFFER_INVALID_DESC                                                                 = 715,
	SET_STREAM_OUTPUT_BUFFERS_INVALID_DESC                                                        = 717,
	CREATERESOURCE_UNRECOGNIZEDDIMENSIONALITY                                                     = 718,
	CREATERESOURCE_UNRECOGNIZEDLAYOUT                                                             = 719,
	CREATERESOURCE_INVALIDDIMENSIONALITY                                                          = 720,
	CREATERESOURCE_INVALIDALIGNMENT                                                               = 721,
	CREATERESOURCE_INVALIDMIPLEVELS                                                               = 722,
	CREATERESOURCE_INVALIDSAMPLEDESC                                                              = 723,
	CREATERESOURCE_INVALIDLAYOUT                                                                  = 724,
	SET_INDEX_BUFFER_INVALID                                                                      = 725,
	SET_VERTEX_BUFFERS_INVALID                                                                    = 726,
	SET_STREAM_OUTPUT_BUFFERS_INVALID                                                             = 727,
	SET_RENDER_TARGETS_INVALID                                                                    = 728,
	CREATEQUERY_HEAP_INVALID_PARAMETERS                                                           = 729,
	BEGIN_END_QUERY_INVALID_PARAMETERS                                                            = 731,
	CLOSE_COMMAND_LIST_OPEN_QUERY                                                                 = 732,
	RESOLVE_QUERY_DATA_INVALID_PARAMETERS                                                         = 733,
	SET_PREDICATION_INVALID_PARAMETERS                                                            = 734,
	TIMESTAMPS_NOT_SUPPORTED                                                                      = 735,
	CREATERESOURCE_UNRECOGNIZEDFORMAT                                                             = 737,
	CREATERESOURCE_INVALIDFORMAT                                                                  = 738,
	GETCOPYABLEFOOTPRINTS_INVALIDSUBRESOURCERANGE                                                 = 739,
	GETCOPYABLEFOOTPRINTS_INVALIDBASEOFFSET                                                       = 740,
	GETCOPYABLELAYOUT_INVALIDSUBRESOURCERANGE                                                     = 739,
	GETCOPYABLELAYOUT_INVALIDBASEOFFSET                                                           = 740,
	RESOURCE_BARRIER_INVALID_HEAP                                                                 = 741,
	CREATE_SAMPLER_INVALID                                                                        = 742,
	CREATECOMMANDSIGNATURE_INVALID                                                                = 743,
	EXECUTE_INDIRECT_INVALID_PARAMETERS                                                           = 744,
	GETGPUVIRTUALADDRESS_INVALID_RESOURCE_DIMENSION                                               = 745,
	CREATERESOURCE_INVALIDCLEARVALUE                                                              = 815,
	CREATERESOURCE_UNRECOGNIZEDCLEARVALUEFORMAT                                                   = 816,
	CREATERESOURCE_INVALIDCLEARVALUEFORMAT                                                        = 817,
	CREATERESOURCE_CLEARVALUEDENORMFLUSH                                                          = 818,
	CLEARRENDERTARGETVIEW_MISMATCHINGCLEARVALUE                                                   = 820,
	CLEARDEPTHSTENCILVIEW_MISMATCHINGCLEARVALUE                                                   = 821,
	MAP_INVALIDHEAP                                                                               = 822,
	UNMAP_INVALIDHEAP                                                                             = 823,
	MAP_INVALIDRESOURCE                                                                           = 824,
	UNMAP_INVALIDRESOURCE                                                                         = 825,
	MAP_INVALIDSUBRESOURCE                                                                        = 826,
	UNMAP_INVALIDSUBRESOURCE                                                                      = 827,
	MAP_INVALIDRANGE                                                                              = 828,
	UNMAP_INVALIDRANGE                                                                            = 829,
	MAP_INVALIDDATAPOINTER                                                                        = 832,
	MAP_INVALIDARG_RETURN                                                                         = 833,
	MAP_OUTOFMEMORY_RETURN                                                                        = 834,
	EXECUTECOMMANDLISTS_BUNDLENOTSUPPORTED                                                        = 835,
	EXECUTECOMMANDLISTS_COMMANDLISTMISMATCH                                                       = 836,
	EXECUTECOMMANDLISTS_OPENCOMMANDLIST                                                           = 837,
	EXECUTECOMMANDLISTS_FAILEDCOMMANDLIST                                                         = 838,
	COPYBUFFERREGION_NULLDST                                                                      = 839,
	COPYBUFFERREGION_INVALIDDSTRESOURCEDIMENSION                                                  = 840,
	COPYBUFFERREGION_DSTRANGEOUTOFBOUNDS                                                          = 841,
	COPYBUFFERREGION_NULLSRC                                                                      = 842,
	COPYBUFFERREGION_INVALIDSRCRESOURCEDIMENSION                                                  = 843,
	COPYBUFFERREGION_SRCRANGEOUTOFBOUNDS                                                          = 844,
	COPYBUFFERREGION_INVALIDCOPYFLAGS                                                             = 845,
	COPYTEXTUREREGION_NULLDST                                                                     = 846,
	COPYTEXTUREREGION_UNRECOGNIZEDDSTTYPE                                                         = 847,
	COPYTEXTUREREGION_INVALIDDSTRESOURCEDIMENSION                                                 = 848,
	COPYTEXTUREREGION_INVALIDDSTRESOURCE                                                          = 849,
	COPYTEXTUREREGION_INVALIDDSTSUBRESOURCE                                                       = 850,
	COPYTEXTUREREGION_INVALIDDSTOFFSET                                                            = 851,
	COPYTEXTUREREGION_UNRECOGNIZEDDSTFORMAT                                                       = 852,
	COPYTEXTUREREGION_INVALIDDSTFORMAT                                                            = 853,
	COPYTEXTUREREGION_INVALIDDSTDIMENSIONS                                                        = 854,
	COPYTEXTUREREGION_INVALIDDSTROWPITCH                                                          = 855,
	COPYTEXTUREREGION_INVALIDDSTPLACEMENT                                                         = 856,
	COPYTEXTUREREGION_INVALIDDSTDSPLACEDFOOTPRINTFORMAT                                           = 857,
	COPYTEXTUREREGION_DSTREGIONOUTOFBOUNDS                                                        = 858,
	COPYTEXTUREREGION_NULLSRC                                                                     = 859,
	COPYTEXTUREREGION_UNRECOGNIZEDSRCTYPE                                                         = 860,
	COPYTEXTUREREGION_INVALIDSRCRESOURCEDIMENSION                                                 = 861,
	COPYTEXTUREREGION_INVALIDSRCRESOURCE                                                          = 862,
	COPYTEXTUREREGION_INVALIDSRCSUBRESOURCE                                                       = 863,
	COPYTEXTUREREGION_INVALIDSRCOFFSET                                                            = 864,
	COPYTEXTUREREGION_UNRECOGNIZEDSRCFORMAT                                                       = 865,
	COPYTEXTUREREGION_INVALIDSRCFORMAT                                                            = 866,
	COPYTEXTUREREGION_INVALIDSRCDIMENSIONS                                                        = 867,
	COPYTEXTUREREGION_INVALIDSRCROWPITCH                                                          = 868,
	COPYTEXTUREREGION_INVALIDSRCPLACEMENT                                                         = 869,
	COPYTEXTUREREGION_INVALIDSRCDSPLACEDFOOTPRINTFORMAT                                           = 870,
	COPYTEXTUREREGION_SRCREGIONOUTOFBOUNDS                                                        = 871,
	COPYTEXTUREREGION_INVALIDDSTCOORDINATES                                                       = 872,
	COPYTEXTUREREGION_INVALIDSRCBOX                                                               = 873,
	COPYTEXTUREREGION_FORMATMISMATCH                                                              = 874,
	COPYTEXTUREREGION_EMPTYBOX                                                                    = 875,
	COPYTEXTUREREGION_INVALIDCOPYFLAGS                                                            = 876,
	RESOLVESUBRESOURCE_INVALID_SUBRESOURCE_INDEX                                                  = 877,
	RESOLVESUBRESOURCE_INVALID_FORMAT                                                             = 878,
	RESOLVESUBRESOURCE_RESOURCE_MISMATCH                                                          = 879,
	RESOLVESUBRESOURCE_INVALID_SAMPLE_COUNT                                                       = 880,
	CREATECOMPUTEPIPELINESTATE_INVALID_SHADER                                                     = 881,
	CREATECOMPUTEPIPELINESTATE_CS_ROOT_SIGNATURE_MISMATCH                                         = 882,
	CREATECOMPUTEPIPELINESTATE_MISSING_ROOT_SIGNATURE                                             = 883,
	CREATEPIPELINESTATE_INVALIDCACHEDBLOB                                                         = 884,
	CREATEPIPELINESTATE_CACHEDBLOBADAPTERMISMATCH                                                 = 885,
	CREATEPIPELINESTATE_CACHEDBLOBDRIVERVERSIONMISMATCH                                           = 886,
	CREATEPIPELINESTATE_CACHEDBLOBDESCMISMATCH                                                    = 887,
	CREATEPIPELINESTATE_CACHEDBLOBIGNORED                                                         = 888,
	WRITETOSUBRESOURCE_INVALIDHEAP                                                                = 889,
	WRITETOSUBRESOURCE_INVALIDRESOURCE                                                            = 890,
	WRITETOSUBRESOURCE_INVALIDBOX                                                                 = 891,
	WRITETOSUBRESOURCE_INVALIDSUBRESOURCE                                                         = 892,
	WRITETOSUBRESOURCE_EMPTYBOX                                                                   = 893,
	READFROMSUBRESOURCE_INVALIDHEAP                                                               = 894,
	READFROMSUBRESOURCE_INVALIDRESOURCE                                                           = 895,
	READFROMSUBRESOURCE_INVALIDBOX                                                                = 896,
	READFROMSUBRESOURCE_INVALIDSUBRESOURCE                                                        = 897,
	READFROMSUBRESOURCE_EMPTYBOX                                                                  = 898,
	TOO_MANY_NODES_SPECIFIED                                                                      = 899,
	INVALID_NODE_INDEX                                                                            = 900,
	GETHEAPPROPERTIES_INVALIDRESOURCE                                                             = 901,
	NODE_MASK_MISMATCH                                                                            = 902,
	COMMAND_LIST_OUTOFMEMORY                                                                      = 903,
	COMMAND_LIST_MULTIPLE_SWAPCHAIN_BUFFER_REFERENCES                                             = 904,
	COMMAND_LIST_TOO_MANY_SWAPCHAIN_REFERENCES                                                    = 905,
	COMMAND_QUEUE_TOO_MANY_SWAPCHAIN_REFERENCES                                                   = 906,
	EXECUTECOMMANDLISTS_WRONGSWAPCHAINBUFFERREFERENCE                                             = 907,
	COMMAND_LIST_SETRENDERTARGETS_INVALIDNUMRENDERTARGETS                                         = 908,
	CREATE_QUEUE_INVALID_TYPE                                                                     = 909,
	CREATE_QUEUE_INVALID_FLAGS                                                                    = 910,
	CREATESHAREDRESOURCE_INVALIDFLAGS                                                             = 911,
	CREATESHAREDRESOURCE_INVALIDFORMAT                                                            = 912,
	CREATESHAREDHEAP_INVALIDFLAGS                                                                 = 913,
	REFLECTSHAREDPROPERTIES_UNRECOGNIZEDPROPERTIES                                                = 914,
	REFLECTSHAREDPROPERTIES_INVALIDSIZE                                                           = 915,
	REFLECTSHAREDPROPERTIES_INVALIDOBJECT                                                         = 916,
	KEYEDMUTEX_INVALIDOBJECT                                                                      = 917,
	KEYEDMUTEX_INVALIDKEY                                                                         = 918,
	KEYEDMUTEX_WRONGSTATE                                                                         = 919,
	CREATE_QUEUE_INVALID_PRIORITY                                                                 = 920,
	OBJECT_DELETED_WHILE_STILL_IN_USE                                                             = 921,
	CREATEPIPELINESTATE_INVALID_FLAGS                                                             = 922,
	HEAP_ADDRESS_RANGE_HAS_NO_RESOURCE                                                            = 923,
	COMMAND_LIST_DRAW_RENDER_TARGET_DELETED                                                       = 924,
	CREATEGRAPHICSPIPELINESTATE_ALL_RENDER_TARGETS_HAVE_UNKNOWN_FORMAT                            = 925,
	HEAP_ADDRESS_RANGE_INTERSECTS_MULTIPLE_BUFFERS                                                = 926,
	EXECUTECOMMANDLISTS_GPU_WRITTEN_READBACK_RESOURCE_MAPPED                                      = 927,
	UNMAP_RANGE_NOT_EMPTY                                                                         = 929,
	MAP_INVALID_NULLRANGE                                                                         = 930,
	UNMAP_INVALID_NULLRANGE                                                                       = 931,
	NO_GRAPHICS_API_SUPPORT                                                                       = 932,
	NO_COMPUTE_API_SUPPORT                                                                        = 933,
	RESOLVESUBRESOURCE_RESOURCE_FLAGS_NOT_SUPPORTED                                               = 934,
	GPU_BASED_VALIDATION_ROOT_ARGUMENT_UNINITIALIZED                                              = 935,
	GPU_BASED_VALIDATION_DESCRIPTOR_HEAP_INDEX_OUT_OF_BOUNDS                                      = 936,
	GPU_BASED_VALIDATION_DESCRIPTOR_TABLE_REGISTER_INDEX_OUT_OF_BOUNDS                            = 937,
	GPU_BASED_VALIDATION_DESCRIPTOR_UNINITIALIZED                                                 = 938,
	GPU_BASED_VALIDATION_DESCRIPTOR_TYPE_MISMATCH                                                 = 939,
	GPU_BASED_VALIDATION_SRV_RESOURCE_DIMENSION_MISMATCH                                          = 940,
	GPU_BASED_VALIDATION_UAV_RESOURCE_DIMENSION_MISMATCH                                          = 941,
	GPU_BASED_VALIDATION_INCOMPATIBLE_RESOURCE_STATE                                              = 942,
	COPYRESOURCE_NULLDST                                                                          = 943,
	COPYRESOURCE_INVALIDDSTRESOURCE                                                               = 944,
	COPYRESOURCE_NULLSRC                                                                          = 945,
	COPYRESOURCE_INVALIDSRCRESOURCE                                                               = 946,
	RESOLVESUBRESOURCE_NULLDST                                                                    = 947,
	RESOLVESUBRESOURCE_INVALIDDSTRESOURCE                                                         = 948,
	RESOLVESUBRESOURCE_NULLSRC                                                                    = 949,
	RESOLVESUBRESOURCE_INVALIDSRCRESOURCE                                                         = 950,
	PIPELINE_STATE_TYPE_MISMATCH                                                                  = 951,
	COMMAND_LIST_DISPATCH_ROOT_SIGNATURE_NOT_SET                                                  = 952,
	COMMAND_LIST_DISPATCH_ROOT_SIGNATURE_MISMATCH                                                 = 953,
	RESOURCE_BARRIER_ZERO_BARRIERS                                                                = 954,
	BEGIN_END_EVENT_MISMATCH                                                                      = 955,
	RESOURCE_BARRIER_POSSIBLE_BEFORE_AFTER_MISMATCH                                               = 956,
	RESOURCE_BARRIER_MISMATCHING_BEGIN_END                                                        = 957,
	GPU_BASED_VALIDATION_INVALID_RESOURCE                                                         = 958,
	USE_OF_ZERO_REFCOUNT_OBJECT                                                                   = 959,
	OBJECT_EVICTED_WHILE_STILL_IN_USE                                                             = 960,
	GPU_BASED_VALIDATION_ROOT_DESCRIPTOR_ACCESS_OUT_OF_BOUNDS                                     = 961,
	CREATEPIPELINELIBRARY_INVALIDLIBRARYBLOB                                                      = 962,
	CREATEPIPELINELIBRARY_DRIVERVERSIONMISMATCH                                                   = 963,
	CREATEPIPELINELIBRARY_ADAPTERVERSIONMISMATCH                                                  = 964,
	CREATEPIPELINELIBRARY_UNSUPPORTED                                                             = 965,
	CREATE_PIPELINELIBRARY                                                                        = 966,
	LIVE_PIPELINELIBRARY                                                                          = 967,
	DESTROY_PIPELINELIBRARY                                                                       = 968,
	STOREPIPELINE_NONAME                                                                          = 969,
	STOREPIPELINE_DUPLICATENAME                                                                   = 970,
	LOADPIPELINE_NAMENOTFOUND                                                                     = 971,
	LOADPIPELINE_INVALIDDESC                                                                      = 972,
	PIPELINELIBRARY_SERIALIZE_NOTENOUGHMEMORY                                                     = 973,
	CREATEGRAPHICSPIPELINESTATE_PS_OUTPUT_RT_OUTPUT_MISMATCH                                      = 974,
	SETEVENTONMULTIPLEFENCECOMPLETION_INVALIDFLAGS                                                = 975,
	CREATE_QUEUE_VIDEO_NOT_SUPPORTED                                                              = 976,
	CREATE_COMMAND_ALLOCATOR_VIDEO_NOT_SUPPORTED                                                  = 977,
	CREATEQUERY_HEAP_VIDEO_DECODE_STATISTICS_NOT_SUPPORTED                                        = 978,
	CREATE_VIDEODECODECOMMANDLIST                                                                 = 979,
	CREATE_VIDEODECODER                                                                           = 980,
	CREATE_VIDEODECODESTREAM                                                                      = 981,
	LIVE_VIDEODECODECOMMANDLIST                                                                   = 982,
	LIVE_VIDEODECODER                                                                             = 983,
	LIVE_VIDEODECODESTREAM                                                                        = 984,
	DESTROY_VIDEODECODECOMMANDLIST                                                                = 985,
	DESTROY_VIDEODECODER                                                                          = 986,
	DESTROY_VIDEODECODESTREAM                                                                     = 987,
	DECODE_FRAME_INVALID_PARAMETERS                                                               = 988,
	DEPRECATED_API                                                                                = 989,
	RESOURCE_BARRIER_MISMATCHING_COMMAND_LIST_TYPE                                                = 990,
	COMMAND_LIST_DESCRIPTOR_TABLE_NOT_SET                                                         = 991,
	COMMAND_LIST_ROOT_CONSTANT_BUFFER_VIEW_NOT_SET                                                = 992,
	COMMAND_LIST_ROOT_SHADER_RESOURCE_VIEW_NOT_SET                                                = 993,
	COMMAND_LIST_ROOT_UNORDERED_ACCESS_VIEW_NOT_SET                                               = 994,
	DISCARD_INVALID_SUBRESOURCE_RANGE                                                             = 995,
	DISCARD_ONE_SUBRESOURCE_FOR_MIPS_WITH_RECTS                                                   = 996,
	DISCARD_NO_RECTS_FOR_NON_TEXTURE2D                                                            = 997,
	COPY_ON_SAME_SUBRESOURCE                                                                      = 998,
	SETRESIDENCYPRIORITY_INVALID_PAGEABLE                                                         = 999,
	GPU_BASED_VALIDATION_UNSUPPORTED                                                              = 1000,
	STATIC_DESCRIPTOR_INVALID_DESCRIPTOR_CHANGE                                                   = 1001,
	DATA_STATIC_DESCRIPTOR_INVALID_DATA_CHANGE                                                    = 1002,
	DATA_STATIC_WHILE_SET_AT_EXECUTE_DESCRIPTOR_INVALID_DATA_CHANGE                               = 1003,
	EXECUTE_BUNDLE_STATIC_DESCRIPTOR_DATA_STATIC_NOT_SET                                          = 1004,
	GPU_BASED_VALIDATION_RESOURCE_ACCESS_OUT_OF_BOUNDS                                            = 1005,
	GPU_BASED_VALIDATION_SAMPLER_MODE_MISMATCH                                                    = 1006,
	CREATE_FENCE_INVALID_FLAGS                                                                    = 1007,
	RESOURCE_BARRIER_DUPLICATE_SUBRESOURCE_TRANSITIONS                                            = 1008,
	SETRESIDENCYPRIORITY_INVALID_PRIORITY                                                         = 1009,
	CREATE_DESCRIPTOR_HEAP_LARGE_NUM_DESCRIPTORS                                                  = 1013,
	BEGIN_EVENT                                                                                   = 1014,
	END_EVENT                                                                                     = 1015,
	CREATEDEVICE_DEBUG_LAYER_STARTUP_OPTIONS                                                      = 1016,
	CREATEDEPTHSTENCILSTATE_DEPTHBOUNDSTEST_UNSUPPORTED                                           = 1017,
	CREATEPIPELINESTATE_DUPLICATE_SUBOBJECT                                                       = 1018,
	CREATEPIPELINESTATE_UNKNOWN_SUBOBJECT                                                         = 1019,
	CREATEPIPELINESTATE_ZERO_SIZE_STREAM                                                          = 1020,
	CREATEPIPELINESTATE_INVALID_STREAM                                                            = 1021,
	CREATEPIPELINESTATE_CANNOT_DEDUCE_TYPE                                                        = 1022,
	COMMAND_LIST_STATIC_DESCRIPTOR_RESOURCE_DIMENSION_MISMATCH                                    = 1023,
	CREATE_COMMAND_QUEUE_INSUFFICIENT_PRIVILEGE_FOR_GLOBAL_REALTIME                               = 1024,
	CREATE_COMMAND_QUEUE_INSUFFICIENT_HARDWARE_SUPPORT_FOR_GLOBAL_REALTIME                        = 1025,
	ATOMICCOPYBUFFER_INVALID_ARCHITECTURE                                                         = 1026,
	ATOMICCOPYBUFFER_NULL_DST                                                                     = 1027,
	ATOMICCOPYBUFFER_INVALID_DST_RESOURCE_DIMENSION                                               = 1028,
	ATOMICCOPYBUFFER_DST_RANGE_OUT_OF_BOUNDS                                                      = 1029,
	ATOMICCOPYBUFFER_NULL_SRC                                                                     = 1030,
	ATOMICCOPYBUFFER_INVALID_SRC_RESOURCE_DIMENSION                                               = 1031,
	ATOMICCOPYBUFFER_SRC_RANGE_OUT_OF_BOUNDS                                                      = 1032,
	ATOMICCOPYBUFFER_INVALID_OFFSET_ALIGNMENT                                                     = 1033,
	ATOMICCOPYBUFFER_NULL_DEPENDENT_RESOURCES                                                     = 1034,
	ATOMICCOPYBUFFER_NULL_DEPENDENT_SUBRESOURCE_RANGES                                            = 1035,
	ATOMICCOPYBUFFER_INVALID_DEPENDENT_RESOURCE                                                   = 1036,
	ATOMICCOPYBUFFER_INVALID_DEPENDENT_SUBRESOURCE_RANGE                                          = 1037,
	ATOMICCOPYBUFFER_DEPENDENT_SUBRESOURCE_OUT_OF_BOUNDS                                          = 1038,
	ATOMICCOPYBUFFER_DEPENDENT_RANGE_OUT_OF_BOUNDS                                                = 1039,
	ATOMICCOPYBUFFER_ZERO_DEPENDENCIES                                                            = 1040,
	DEVICE_CREATE_SHARED_HANDLE_INVALIDARG                                                        = 1041,
	DESCRIPTOR_HANDLE_WITH_INVALID_RESOURCE                                                       = 1042,
	SETDEPTHBOUNDS_INVALIDARGS                                                                    = 1043,
	GPU_BASED_VALIDATION_RESOURCE_STATE_IMPRECISE                                                 = 1044,
	COMMAND_LIST_PIPELINE_STATE_NOT_SET                                                           = 1045,
	CREATEGRAPHICSPIPELINESTATE_SHADER_MODEL_MISMATCH                                             = 1046,
	OBJECT_ACCESSED_WHILE_STILL_IN_USE                                                            = 1047,
	PROGRAMMABLE_MSAA_UNSUPPORTED                                                                 = 1048,
	SETSAMPLEPOSITIONS_INVALIDARGS                                                                = 1049,
	RESOLVESUBRESOURCEREGION_INVALID_RECT                                                         = 1050,
	CREATE_VIDEODECODECOMMANDQUEUE                                                                = 1051,
	CREATE_VIDEOPROCESSCOMMANDLIST                                                                = 1052,
	CREATE_VIDEOPROCESSCOMMANDQUEUE                                                               = 1053,
	LIVE_VIDEODECODECOMMANDQUEUE                                                                  = 1054,
	LIVE_VIDEOPROCESSCOMMANDLIST                                                                  = 1055,
	LIVE_VIDEOPROCESSCOMMANDQUEUE                                                                 = 1056,
	DESTROY_VIDEODECODECOMMANDQUEUE                                                               = 1057,
	DESTROY_VIDEOPROCESSCOMMANDLIST                                                               = 1058,
	DESTROY_VIDEOPROCESSCOMMANDQUEUE                                                              = 1059,
	CREATE_VIDEOPROCESSOR                                                                         = 1060,
	CREATE_VIDEOPROCESSSTREAM                                                                     = 1061,
	LIVE_VIDEOPROCESSOR                                                                           = 1062,
	LIVE_VIDEOPROCESSSTREAM                                                                       = 1063,
	DESTROY_VIDEOPROCESSOR                                                                        = 1064,
	DESTROY_VIDEOPROCESSSTREAM                                                                    = 1065,
	PROCESS_FRAME_INVALID_PARAMETERS                                                              = 1066,
	COPY_INVALIDLAYOUT                                                                            = 1067,
	CREATE_CRYPTO_SESSION                                                                         = 1068,
	CREATE_CRYPTO_SESSION_POLICY                                                                  = 1069,
	CREATE_PROTECTED_RESOURCE_SESSION                                                             = 1070,
	LIVE_CRYPTO_SESSION                                                                           = 1071,
	LIVE_CRYPTO_SESSION_POLICY                                                                    = 1072,
	LIVE_PROTECTED_RESOURCE_SESSION                                                               = 1073,
	DESTROY_CRYPTO_SESSION                                                                        = 1074,
	DESTROY_CRYPTO_SESSION_POLICY                                                                 = 1075,
	DESTROY_PROTECTED_RESOURCE_SESSION                                                            = 1076,
	PROTECTED_RESOURCE_SESSION_UNSUPPORTED                                                        = 1077,
	FENCE_INVALIDOPERATION                                                                        = 1078,
	CREATEQUERY_HEAP_COPY_QUEUE_TIMESTAMPS_NOT_SUPPORTED                                          = 1079,
	SAMPLEPOSITIONS_MISMATCH_DEFERRED                                                             = 1080,
	SAMPLEPOSITIONS_MISMATCH_RECORDTIME_ASSUMEDFROMFIRSTUSE                                       = 1081,
	SAMPLEPOSITIONS_MISMATCH_RECORDTIME_ASSUMEDFROMCLEAR                                          = 1082,
	CREATE_VIDEODECODERHEAP                                                                       = 1083,
	LIVE_VIDEODECODERHEAP                                                                         = 1084,
	DESTROY_VIDEODECODERHEAP                                                                      = 1085,
	OPENEXISTINGHEAP_INVALIDARG_RETURN                                                            = 1086,
	OPENEXISTINGHEAP_OUTOFMEMORY_RETURN                                                           = 1087,
	OPENEXISTINGHEAP_INVALIDADDRESS                                                               = 1088,
	OPENEXISTINGHEAP_INVALIDHANDLE                                                                = 1089,
	WRITEBUFFERIMMEDIATE_INVALID_DEST                                                             = 1090,
	WRITEBUFFERIMMEDIATE_INVALID_MODE                                                             = 1091,
	WRITEBUFFERIMMEDIATE_INVALID_ALIGNMENT                                                        = 1092,
	WRITEBUFFERIMMEDIATE_NOT_SUPPORTED                                                            = 1093,
	SETVIEWINSTANCEMASK_INVALIDARGS                                                               = 1094,
	VIEW_INSTANCING_UNSUPPORTED                                                                   = 1095,
	VIEW_INSTANCING_INVALIDARGS                                                                   = 1096,
	COPYTEXTUREREGION_MISMATCH_DECODE_REFERENCE_ONLY_FLAG                                         = 1097,
	COPYRESOURCE_MISMATCH_DECODE_REFERENCE_ONLY_FLAG                                              = 1098,
	CREATE_VIDEO_DECODE_HEAP_CAPS_FAILURE                                                         = 1099,
	CREATE_VIDEO_DECODE_HEAP_CAPS_UNSUPPORTED                                                     = 1100,
	VIDEO_DECODE_SUPPORT_INVALID_INPUT                                                            = 1101,
	CREATE_VIDEO_DECODER_UNSUPPORTED                                                              = 1102,
	CREATEGRAPHICSPIPELINESTATE_METADATA_ERROR                                                    = 1103,
	CREATEGRAPHICSPIPELINESTATE_VIEW_INSTANCING_VERTEX_SIZE_EXCEEDED                              = 1104,
	CREATEGRAPHICSPIPELINESTATE_RUNTIME_INTERNAL_ERROR                                            = 1105,
	NO_VIDEO_API_SUPPORT                                                                          = 1106,
	VIDEO_PROCESS_SUPPORT_INVALID_INPUT                                                           = 1107,
	CREATE_VIDEO_PROCESSOR_CAPS_FAILURE                                                           = 1108,
	VIDEO_PROCESS_SUPPORT_UNSUPPORTED_FORMAT                                                      = 1109,
	VIDEO_DECODE_FRAME_INVALID_ARGUMENT                                                           = 1110,
	ENQUEUE_MAKE_RESIDENT_INVALID_FLAGS                                                           = 1111,
	OPENEXISTINGHEAP_UNSUPPORTED                                                                  = 1112,
	VIDEO_PROCESS_FRAMES_INVALID_ARGUMENT                                                         = 1113,
	VIDEO_DECODE_SUPPORT_UNSUPPORTED                                                              = 1114,
	CREATE_COMMANDRECORDER                                                                        = 1115,
	LIVE_COMMANDRECORDER                                                                          = 1116,
	DESTROY_COMMANDRECORDER                                                                       = 1117,
	CREATE_COMMAND_RECORDER_VIDEO_NOT_SUPPORTED                                                   = 1118,
	CREATE_COMMAND_RECORDER_INVALID_SUPPORT_FLAGS                                                 = 1119,
	CREATE_COMMAND_RECORDER_INVALID_FLAGS                                                         = 1120,
	CREATE_COMMAND_RECORDER_MORE_RECORDERS_THAN_LOGICAL_PROCESSORS                                = 1121,
	CREATE_COMMANDPOOL                                                                            = 1122,
	LIVE_COMMANDPOOL                                                                              = 1123,
	DESTROY_COMMANDPOOL                                                                           = 1124,
	CREATE_COMMAND_POOL_INVALID_FLAGS                                                             = 1125,
	CREATE_COMMAND_LIST_VIDEO_NOT_SUPPORTED                                                       = 1126,
	COMMAND_RECORDER_SUPPORT_FLAGS_MISMATCH                                                       = 1127,
	COMMAND_RECORDER_CONTENTION                                                                   = 1128,
	COMMAND_RECORDER_USAGE_WITH_CREATECOMMANDLIST_COMMAND_LIST                                    = 1129,
	COMMAND_ALLOCATOR_USAGE_WITH_CREATECOMMANDLIST1_COMMAND_LIST                                  = 1130,
	CANNOT_EXECUTE_EMPTY_COMMAND_LIST                                                             = 1131,
	CANNOT_RESET_COMMAND_POOL_WITH_OPEN_COMMAND_LISTS                                             = 1132,
	CANNOT_USE_COMMAND_RECORDER_WITHOUT_CURRENT_TARGET                                            = 1133,
	CANNOT_CHANGE_COMMAND_RECORDER_TARGET_WHILE_RECORDING                                         = 1134,
	COMMAND_POOL_SYNC                                                                             = 1135,
	EVICT_UNDERFLOW                                                                               = 1136,
	CREATE_META_COMMAND                                                                           = 1137,
	LIVE_META_COMMAND                                                                             = 1138,
	DESTROY_META_COMMAND                                                                          = 1139,
	COPYBUFFERREGION_INVALID_DST_RESOURCE                                                         = 1140,
	COPYBUFFERREGION_INVALID_SRC_RESOURCE                                                         = 1141,
	ATOMICCOPYBUFFER_INVALID_DST_RESOURCE                                                         = 1142,
	ATOMICCOPYBUFFER_INVALID_SRC_RESOURCE                                                         = 1143,
	CREATEPLACEDRESOURCEONBUFFER_NULL_BUFFER                                                      = 1144,
	CREATEPLACEDRESOURCEONBUFFER_NULL_RESOURCE_DESC                                               = 1145,
	CREATEPLACEDRESOURCEONBUFFER_UNSUPPORTED                                                      = 1146,
	CREATEPLACEDRESOURCEONBUFFER_INVALID_BUFFER_DIMENSION                                         = 1147,
	CREATEPLACEDRESOURCEONBUFFER_INVALID_BUFFER_FLAGS                                             = 1148,
	CREATEPLACEDRESOURCEONBUFFER_INVALID_BUFFER_OFFSET                                            = 1149,
	CREATEPLACEDRESOURCEONBUFFER_INVALID_RESOURCE_DIMENSION                                       = 1150,
	CREATEPLACEDRESOURCEONBUFFER_INVALID_RESOURCE_FLAGS                                           = 1151,
	CREATEPLACEDRESOURCEONBUFFER_OUTOFMEMORY_RETURN                                               = 1152,
	CANNOT_CREATE_GRAPHICS_AND_VIDEO_COMMAND_RECORDER                                             = 1153,
	UPDATETILEMAPPINGS_POSSIBLY_MISMATCHING_PROPERTIES                                            = 1154,
	CREATE_COMMAND_LIST_INVALID_COMMAND_LIST_TYPE                                                 = 1155,
	CLEARUNORDEREDACCESSVIEW_INCOMPATIBLE_WITH_STRUCTURED_BUFFERS                                 = 1156,
	COMPUTE_ONLY_DEVICE_OPERATION_UNSUPPORTED                                                     = 1157,
	BUILD_RAYTRACING_ACCELERATION_STRUCTURE_INVALID                                               = 1158,
	EMIT_RAYTRACING_ACCELERATION_STRUCTURE_POSTBUILD_INFO_INVALID                                 = 1159,
	COPY_RAYTRACING_ACCELERATION_STRUCTURE_INVALID                                                = 1160,
	DISPATCH_RAYS_INVALID                                                                         = 1161,
	GET_RAYTRACING_ACCELERATION_STRUCTURE_PREBUILD_INFO_INVALID                                   = 1162,
	CREATE_LIFETIMETRACKER                                                                        = 1163,
	LIVE_LIFETIMETRACKER                                                                          = 1164,
	DESTROY_LIFETIMETRACKER                                                                       = 1165,
	DESTROYOWNEDOBJECT_OBJECTNOTOWNED                                                             = 1166,
	CREATE_TRACKEDWORKLOAD                                                                        = 1167,
	LIVE_TRACKEDWORKLOAD                                                                          = 1168,
	DESTROY_TRACKEDWORKLOAD                                                                       = 1169,
	RENDER_PASS_ERROR                                                                             = 1170,
	META_COMMAND_ID_INVALID                                                                       = 1171,
	META_COMMAND_UNSUPPORTED_PARAMS                                                               = 1172,
	META_COMMAND_FAILED_ENUMERATION                                                               = 1173,
	META_COMMAND_PARAMETER_SIZE_MISMATCH                                                          = 1174,
	UNINITIALIZED_META_COMMAND                                                                    = 1175,
	META_COMMAND_INVALID_GPU_VIRTUAL_ADDRESS                                                      = 1176,
	CREATE_VIDEOENCODECOMMANDLIST                                                                 = 1177,
	LIVE_VIDEOENCODECOMMANDLIST                                                                   = 1178,
	DESTROY_VIDEOENCODECOMMANDLIST                                                                = 1179,
	CREATE_VIDEOENCODECOMMANDQUEUE                                                                = 1180,
	LIVE_VIDEOENCODECOMMANDQUEUE                                                                  = 1181,
	DESTROY_VIDEOENCODECOMMANDQUEUE                                                               = 1182,
	CREATE_VIDEOMOTIONESTIMATOR                                                                   = 1183,
	LIVE_VIDEOMOTIONESTIMATOR                                                                     = 1184,
	DESTROY_VIDEOMOTIONESTIMATOR                                                                  = 1185,
	CREATE_VIDEOMOTIONVECTORHEAP                                                                  = 1186,
	LIVE_VIDEOMOTIONVECTORHEAP                                                                    = 1187,
	DESTROY_VIDEOMOTIONVECTORHEAP                                                                 = 1188,
	MULTIPLE_TRACKED_WORKLOADS                                                                    = 1189,
	MULTIPLE_TRACKED_WORKLOAD_PAIRS                                                               = 1190,
	OUT_OF_ORDER_TRACKED_WORKLOAD_PAIR                                                            = 1191,
	CANNOT_ADD_TRACKED_WORKLOAD                                                                   = 1192,
	INCOMPLETE_TRACKED_WORKLOAD_PAIR                                                              = 1193,
	CREATE_STATE_OBJECT_ERROR                                                                     = 1194,
	GET_SHADER_IDENTIFIER_ERROR                                                                   = 1195,
	GET_SHADER_STACK_SIZE_ERROR                                                                   = 1196,
	GET_PIPELINE_STACK_SIZE_ERROR                                                                 = 1197,
	SET_PIPELINE_STACK_SIZE_ERROR                                                                 = 1198,
	GET_SHADER_IDENTIFIER_SIZE_INVALID                                                            = 1199,
	CHECK_DRIVER_MATCHING_IDENTIFIER_INVALID                                                      = 1200,
	CHECK_DRIVER_MATCHING_IDENTIFIER_DRIVER_REPORTED_ISSUE                                        = 1201,
	RENDER_PASS_INVALID_RESOURCE_BARRIER                                                          = 1202,
	RENDER_PASS_DISALLOWED_API_CALLED                                                             = 1203,
	RENDER_PASS_CANNOT_NEST_RENDER_PASSES                                                         = 1204,
	RENDER_PASS_CANNOT_END_WITHOUT_BEGIN                                                          = 1205,
	RENDER_PASS_CANNOT_CLOSE_COMMAND_LIST                                                         = 1206,
	RENDER_PASS_GPU_WORK_WHILE_SUSPENDED                                                          = 1207,
	RENDER_PASS_MISMATCHING_SUSPEND_RESUME                                                        = 1208,
	RENDER_PASS_NO_PRIOR_SUSPEND_WITHIN_EXECUTECOMMANDLISTS                                       = 1209,
	RENDER_PASS_NO_SUBSEQUENT_RESUME_WITHIN_EXECUTECOMMANDLISTS                                   = 1210,
	TRACKED_WORKLOAD_COMMAND_QUEUE_MISMATCH                                                       = 1211,
	TRACKED_WORKLOAD_NOT_SUPPORTED                                                                = 1212,
	RENDER_PASS_MISMATCHING_NO_ACCESS                                                             = 1213,
	RENDER_PASS_UNSUPPORTED_RESOLVE                                                               = 1214,
	CLEARUNORDEREDACCESSVIEW_INVALID_RESOURCE_PTR                                                 = 1215,
	WINDOWS7_FENCE_OUTOFORDER_SIGNAL                                                              = 1216,
	WINDOWS7_FENCE_OUTOFORDER_WAIT                                                                = 1217,
	VIDEO_CREATE_MOTION_ESTIMATOR_INVALID_ARGUMENT                                                = 1218,
	VIDEO_CREATE_MOTION_VECTOR_HEAP_INVALID_ARGUMENT                                              = 1219,
	ESTIMATE_MOTION_INVALID_ARGUMENT                                                              = 1220,
	RESOLVE_MOTION_VECTOR_HEAP_INVALID_ARGUMENT                                                   = 1221,
	GETGPUVIRTUALADDRESS_INVALID_HEAP_TYPE                                                        = 1222,
	SET_BACKGROUND_PROCESSING_MODE_INVALID_ARGUMENT                                               = 1223,
	CREATE_COMMAND_LIST_INVALID_COMMAND_LIST_TYPE_FOR_FEATURE_LEVEL                               = 1224,
	CREATE_VIDEOEXTENSIONCOMMAND                                                                  = 1225,
	LIVE_VIDEOEXTENSIONCOMMAND                                                                    = 1226,
	DESTROY_VIDEOEXTENSIONCOMMAND                                                                 = 1227,
	INVALID_VIDEO_EXTENSION_COMMAND_ID                                                            = 1228,
	VIDEO_EXTENSION_COMMAND_INVALID_ARGUMENT                                                      = 1229,
	CREATE_ROOT_SIGNATURE_NOT_UNIQUE_IN_DXIL_LIBRARY                                              = 1230,
	VARIABLE_SHADING_RATE_NOT_ALLOWED_WITH_TIR                                                    = 1231,
	GEOMETRY_SHADER_OUTPUTTING_BOTH_VIEWPORT_ARRAY_INDEX_AND_SHADING_RATE_NOT_SUPPORTED_ON_DEVICE = 1232,
	RSSETSHADING_RATE_INVALID_SHADING_RATE                                                        = 1233,
	RSSETSHADING_RATE_SHADING_RATE_NOT_PERMITTED_BY_CAP                                           = 1234,
	RSSETSHADING_RATE_INVALID_COMBINER                                                            = 1235,
	RSSETSHADINGRATEIMAGE_REQUIRES_TIER_2                                                         = 1236,
	RSSETSHADINGRATE_REQUIRES_TIER_1                                                              = 1237,
	SHADING_RATE_IMAGE_INCORRECT_FORMAT                                                           = 1238,
	SHADING_RATE_IMAGE_INCORRECT_ARRAY_SIZE                                                       = 1239,
	SHADING_RATE_IMAGE_INCORRECT_MIP_LEVEL                                                        = 1240,
	SHADING_RATE_IMAGE_INCORRECT_SAMPLE_COUNT                                                     = 1241,
	SHADING_RATE_IMAGE_INCORRECT_SAMPLE_QUALITY                                                   = 1242,
	NON_RETAIL_SHADER_MODEL_WONT_VALIDATE                                                         = 1243,
	CREATEGRAPHICSPIPELINESTATE_AS_ROOT_SIGNATURE_MISMATCH                                        = 1244,
	CREATEGRAPHICSPIPELINESTATE_MS_ROOT_SIGNATURE_MISMATCH                                        = 1245,
	ADD_TO_STATE_OBJECT_ERROR                                                                     = 1246,
	CREATE_PROTECTED_RESOURCE_SESSION_INVALID_ARGUMENT                                            = 1247,
	CREATEGRAPHICSPIPELINESTATE_MS_PSO_DESC_MISMATCH                                              = 1248,
	CREATEPIPELINESTATE_MS_INCOMPLETE_TYPE                                                        = 1249,
	CREATEGRAPHICSPIPELINESTATE_AS_NOT_MS_MISMATCH                                                = 1250,
	CREATEGRAPHICSPIPELINESTATE_MS_NOT_PS_MISMATCH                                                = 1251,
	NONZERO_SAMPLER_FEEDBACK_MIP_REGION_WITH_INCOMPATIBLE_FORMAT                                  = 1252,
	CREATEGRAPHICSPIPELINESTATE_INPUTLAYOUT_SHADER_MISMATCH                                       = 1253,
	EMPTY_DISPATCH                                                                                = 1254,
	RESOURCE_FORMAT_REQUIRES_SAMPLER_FEEDBACK_CAPABILITY                                          = 1255,
	SAMPLER_FEEDBACK_MAP_INVALID_MIP_REGION                                                       = 1256,
	SAMPLER_FEEDBACK_MAP_INVALID_DIMENSION                                                        = 1257,
	SAMPLER_FEEDBACK_MAP_INVALID_SAMPLE_COUNT                                                     = 1258,
	SAMPLER_FEEDBACK_MAP_INVALID_SAMPLE_QUALITY                                                   = 1259,
	SAMPLER_FEEDBACK_MAP_INVALID_LAYOUT                                                           = 1260,
	SAMPLER_FEEDBACK_MAP_REQUIRES_UNORDERED_ACCESS_FLAG                                           = 1261,
	SAMPLER_FEEDBACK_CREATE_UAV_NULL_ARGUMENTS                                                    = 1262,
	SAMPLER_FEEDBACK_UAV_REQUIRES_SAMPLER_FEEDBACK_CAPABILITY                                     = 1263,
	SAMPLER_FEEDBACK_CREATE_UAV_REQUIRES_FEEDBACK_MAP_FORMAT                                      = 1264,
	CREATEMESHSHADER_INVALIDSHADERBYTECODE                                                        = 1265,
	CREATEMESHSHADER_OUTOFMEMORY                                                                  = 1266,
	CREATEMESHSHADERWITHSTREAMOUTPUT_INVALIDSHADERTYPE                                            = 1267,
	RESOLVESUBRESOURCE_SAMPLER_FEEDBACK_TRANSCODE_INVALID_FORMAT                                  = 1268,
	RESOLVESUBRESOURCE_SAMPLER_FEEDBACK_INVALID_MIP_LEVEL_COUNT                                   = 1269,
	RESOLVESUBRESOURCE_SAMPLER_FEEDBACK_TRANSCODE_ARRAY_SIZE_MISMATCH                             = 1270,
	SAMPLER_FEEDBACK_CREATE_UAV_MISMATCHING_TARGETED_RESOURCE                                     = 1271,
	CREATEMESHSHADER_OUTPUTEXCEEDSMAXSIZE                                                         = 1272,
	CREATEMESHSHADER_GROUPSHAREDEXCEEDSMAXSIZE                                                    = 1273,
	VERTEX_SHADER_OUTPUTTING_BOTH_VIEWPORT_ARRAY_INDEX_AND_SHADING_RATE_NOT_SUPPORTED_ON_DEVICE   = 1274,
	MESH_SHADER_OUTPUTTING_BOTH_VIEWPORT_ARRAY_INDEX_AND_SHADING_RATE_NOT_SUPPORTED_ON_DEVICE     = 1275,
	CREATEMESHSHADER_MISMATCHEDASMSPAYLOADSIZE                                                    = 1276,
	CREATE_ROOT_SIGNATURE_UNBOUNDED_STATIC_DESCRIPTORS                                            = 1277,
	CREATEAMPLIFICATIONSHADER_INVALIDSHADERBYTECODE                                               = 1278,
	CREATEAMPLIFICATIONSHADER_OUTOFMEMORY                                                         = 1279,
	MESSAGES_END                                                                            = 1280,
}

MESSAGE :: struct {
	Category:              MESSAGE_CATEGORY,
	Severity:              MESSAGE_SEVERITY,
	ID:                    MESSAGE_ID,
	pDescription:          cstring,
	DescriptionByteLength: SIZE_T,
}

INFO_QUEUE_FILTER_DESC :: struct {
	NumCategories: u32,
	pCategoryList: ^MESSAGE_CATEGORY,
	NumSeverities: u32,
	pSeverityList: ^MESSAGE_SEVERITY,
	NumIDs:        u32,
	pIDList:       ^MESSAGE_ID,
}

INFO_QUEUE_FILTER :: struct {
	AllowList: INFO_QUEUE_FILTER_DESC,
	DenyList:  INFO_QUEUE_FILTER_DESC,
}


IInfoQueue_UUID :: "0742a90b-c387-483f-b946-30a7e4e61458"
IInfoQueue :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12infoqueue_vtable: ^IInfoQueue_VTable,
}
IInfoQueue_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetMessageCountLimit:                         proc "stdcall" (this: ^IInfoQueue, MessageCountLimit: u64) -> HRESULT,
	ClearStoredMessages:                          proc "stdcall" (this: ^IInfoQueue),
	GetMessageA:                                  proc "stdcall" (this: ^IInfoQueue, MessageIndex: u64, pMessage: ^MESSAGE, pMessageByteLength: ^SIZE_T) -> HRESULT,
	GetNumMessagesAllowedByStorageFilter:         proc "stdcall" (this: ^IInfoQueue) -> u64,
	GetNumMessagesDeniedByStorageFilter:          proc "stdcall" (this: ^IInfoQueue) -> u64,
	GetNumStoredMessages:                         proc "stdcall" (this: ^IInfoQueue) -> u64,
	GetNumStoredMessagesAllowedByRetrievalFilter: proc "stdcall" (this: ^IInfoQueue) -> u64,
	GetNumMessagesDiscardedByMessageCountLimit:   proc "stdcall" (this: ^IInfoQueue) -> u64,
	GetMessageCountLimit:                         proc "stdcall" (this: ^IInfoQueue) -> u64,
	AddStorageFilterEntries:                      proc "stdcall" (this: ^IInfoQueue, pFilter: ^INFO_QUEUE_FILTER) -> HRESULT,
	GetStorageFilter:                             proc "stdcall" (this: ^IInfoQueue, pFilter: ^INFO_QUEUE_FILTER, pFilterByteLength: ^SIZE_T) -> HRESULT,
	ClearStorageFilter:                           proc "stdcall" (this: ^IInfoQueue),
	PushEmptyStorageFilter:                       proc "stdcall" (this: ^IInfoQueue) -> HRESULT,
	PushCopyOfStorageFilter:                      proc "stdcall" (this: ^IInfoQueue) -> HRESULT,
	PushStorageFilter:                            proc "stdcall" (this: ^IInfoQueue, pFilter: ^INFO_QUEUE_FILTER) -> HRESULT,
	PopStorageFilter:                             proc "stdcall" (this: ^IInfoQueue),
	GetStorageFilterStackSize:                    proc "stdcall" (this: ^IInfoQueue) -> u32,
	AddRetrievalFilterEntries:                    proc "stdcall" (this: ^IInfoQueue, pFilter: ^INFO_QUEUE_FILTER) -> HRESULT,
	GetRetrievalFilter:                           proc "stdcall" (this: ^IInfoQueue, pFilter: ^INFO_QUEUE_FILTER, pFilterByteLength: ^SIZE_T) -> HRESULT,
	ClearRetrievalFilter:                         proc "stdcall" (this: ^IInfoQueue),
	PushEmptyRetrievalFilter:                     proc "stdcall" (this: ^IInfoQueue) -> HRESULT,
	PushCopyOfRetrievalFilter:                    proc "stdcall" (this: ^IInfoQueue) -> HRESULT,
	PushRetrievalFilter:                          proc "stdcall" (this: ^IInfoQueue, pFilter: ^INFO_QUEUE_FILTER) -> HRESULT,
	PopRetrievalFilter:                           proc "stdcall" (this: ^IInfoQueue),
	GetRetrievalFilterStackSize:                  proc "stdcall" (this: ^IInfoQueue) -> u32,
	AddMessage:                                   proc "stdcall" (this: ^IInfoQueue, Category: MESSAGE_CATEGORY, Severity: MESSAGE_SEVERITY, ID: MESSAGE_ID, pDescription: cstring) -> HRESULT,
	AddApplicationMessage:                        proc "stdcall" (this: ^IInfoQueue, Severity: MESSAGE_SEVERITY, pDescription: cstring) -> HRESULT,
	SetBreakOnCategory:                           proc "stdcall" (this: ^IInfoQueue, Category: MESSAGE_CATEGORY, bEnable: BOOL) -> HRESULT,
	SetBreakOnSeverity:                           proc "stdcall" (this: ^IInfoQueue, Severity: MESSAGE_SEVERITY, bEnable: BOOL) -> HRESULT,
	SetBreakOnID:                                 proc "stdcall" (this: ^IInfoQueue, ID: MESSAGE_ID, bEnable: BOOL) -> HRESULT,
	GetBreakOnCategory:                           proc "stdcall" (this: ^IInfoQueue, Category: MESSAGE_CATEGORY) -> BOOL,
	GetBreakOnSeverity:                           proc "stdcall" (this: ^IInfoQueue, Severity: MESSAGE_SEVERITY) -> BOOL,
	GetBreakOnID:                                 proc "stdcall" (this: ^IInfoQueue, ID: MESSAGE_ID) -> BOOL,
	SetMuteDebugOutput:                           proc "stdcall" (this: ^IInfoQueue, bMute: BOOL),
	GetMuteDebugOutput:                           proc "stdcall" (this: ^IInfoQueue) -> BOOL,
}

PFN_CREATE_DEVICE :: #type proc "c" (a0: ^IUnknown, a1: FEATURE_LEVEL, a2: ^IID, a3: ^rawptr) -> HRESULT
PFN_GET_DEBUG_INTERFACE :: #type proc "c" (a0: ^IID, a1: ^rawptr) -> HRESULT

AXIS_SHADING_RATE :: enum i32 {
	_1X = 0,
	_2X = 1,
	_4X = 2,
}

SHADING_RATE :: enum i32 {
	_1X1 = 0,
	_1X2 = 1,
	_2X1 = 4,
	_2X2 = 5,
	_2X4 = 6,
	_4X2 = 9,
	_4X4 = 10,
}

SHADING_RATE_COMBINER :: enum i32 {
	PASSTHROUGH = 0,
	OVERRIDE    = 1,
	MIN         = 2,
	MAX         = 3,
	SUM         = 4,
}


IGraphicsCommandList5_UUID :: "55050859-4024-474c-87f5-6472eaee44ea"
IGraphicsCommandList5 :: struct #raw_union {
	#subtype id3d12graphicscommandlist4: IGraphicsCommandList4,
	using id3d12graphicscommandlist5_vtable: ^IGraphicsCommandList5_VTable,
}
IGraphicsCommandList5_VTable :: struct {
	using id3d12graphicscommandlist4_vtable: IGraphicsCommandList4_VTable,
	RSSetShadingRate:      proc "stdcall" (this: ^IGraphicsCommandList5, baseShadingRate: SHADING_RATE, combiners: ^SHADING_RATE_COMBINER),
	RSSetShadingRateImage: proc "stdcall" (this: ^IGraphicsCommandList5, shadingRateImage: ^IResource),
}

DISPATCH_MESH_ARGUMENTS :: struct {
	ThreadGroupCountX: u32,
	ThreadGroupCountY: u32,
	ThreadGroupCountZ: u32,
}


IGraphicsCommandList6_UUID :: "c3827890-e548-4cfa-96cf-5689a9370f80"
IGraphicsCommandList6 :: struct #raw_union {
	#subtype id3d12graphicscommandlist5: IGraphicsCommandList5,
	using id3d12graphicscommandlist6_vtable: ^IGraphicsCommandList6_VTable,
}
IGraphicsCommandList6_VTable :: struct {
	using id3d12graphicscommandlist5_vtable: IGraphicsCommandList5_VTable,
	DispatchMesh: proc "stdcall" (this: ^IGraphicsCommandList6, ThreadGroupCountX: u32, ThreadGroupCountY: u32, ThreadGroupCountZ: u32),
}

SHADER_VERSION_TYPE :: enum i32 {
	PIXEL_SHADER    = 0,
	VERTEX_SHADER   = 1,
	GEOMETRY_SHADER = 2,

	HULL_SHADER     = 3,
	DOMAIN_SHADER   = 4,
	COMPUTE_SHADER  = 5,

	RESERVED0       = 65520,
}

SIGNATURE_PARAMETER_DESC :: struct {
	SemanticName:    cstring,
	SemanticIndex:   u32,
	Register:        u32,
	SystemValueType: NAME,
	ComponentType:   REGISTER_COMPONENT_TYPE,
	Mask:            u8,

	ReadWriteMask:   u8,

	Stream:          u32,
	MinPrecision:    MIN_PRECISION,
}

SHADER_BUFFER_DESC :: struct {
	Name:      cstring,
	Type:      CBUFFER_TYPE,
	Variables: u32,
	Size:      u32,
	uFlags:    u32,
}

SHADER_VARIABLE_DESC :: struct {
	Name:         cstring,
	StartOffset:  u32,
	Size:         u32,
	uFlags:       u32,
	DefaultValue: rawptr,
	StartTexture: u32,
	TextureSize:  u32,
	StartSampler: u32,
	SamplerSize:  u32,
}

SHADER_TYPE_DESC :: struct {
	Class:    SHADER_VARIABLE_CLASS,
	Type:     SHADER_VARIABLE_TYPE,
	Rows:     u32,
	Columns:  u32,
	Elements: u32,
	Members:  u32,
	Offset:   u32,
	Name:     cstring,
}
SHADER_DESC :: struct {
	Version:                     u32,
	Creator:                     cstring,
	Flags:                       u32,

	ConstantBuffers:             u32,
	BoundResources:              u32,
	InputParameters:             u32,
	OutputParameters:            u32,

	InstructionCount:            u32,
	TempRegisterCount:           u32,
	TempArrayCount:              u32,
	DefCount:                    u32,
	DclCount:                    u32,
	TextureNormalInstructions:   u32,
	TextureLoadInstructions:     u32,
	TextureCompInstructions:     u32,
	TextureBiasInstructions:     u32,
	TextureGradientInstructions: u32,
	FloatInstructionCount:       u32,
	IntInstructionCount:         u32,
	UintInstructionCount:        u32,
	StaticFlowControlCount:      u32,
	DynamicFlowControlCount:     u32,
	MacroInstructionCount:       u32,
	ArrayInstructionCount:       u32,
	CutInstructionCount:         u32,
	EmitInstructionCount:        u32,
	GSOutputTopology:            PRIMITIVE_TOPOLOGY,
	GSMaxOutputVertexCount:      u32,
	InputPrimitive:              PRIMITIVE,
	PatchConstantParameters:     u32,
	cGSInstanceCount:            u32,
	cControlPoints:              u32,
	HSOutputPrimitive:           TESSELLATOR_OUTPUT_PRIMITIVE,
	HSPartitioning:              TESSELLATOR_PARTITIONING,
	TessellatorDomain:           TESSELLATOR_DOMAIN,

	cBarrierInstructions:        u32,
	cInterlockedInstructions:    u32,
	cTextureStoreInstructions:   u32,
}

SHADER_INPUT_BIND_DESC :: struct {
	Name:       cstring,
	Type:       SHADER_INPUT_TYPE,
	BindPoint:  u32,
	BindCount:  u32,

	uFlags:     u32,
	ReturnType: RESOURCE_RETURN_TYPE,
	Dimension:  SRV_DIMENSION,
	NumSamples: u32,
	Space:      u32,
	uID:        u32,
}

LIBRARY_DESC :: struct {
	Creator:       cstring,
	Flags:         u32,
	FunctionCount: u32,
}

FUNCTION_DESC :: struct {
	Version:                     u32,
	Creator:                     cstring,
	Flags:                       u32,

	ConstantBuffers:             u32,
	BoundResources:              u32,

	InstructionCount:            u32,
	TempRegisterCount:           u32,
	TempArrayCount:              u32,
	DefCount:                    u32,
	DclCount:                    u32,
	TextureNormalInstructions:   u32,
	TextureLoadInstructions:     u32,
	TextureCompInstructions:     u32,
	TextureBiasInstructions:     u32,
	TextureGradientInstructions: u32,
	FloatInstructionCount:       u32,
	IntInstructionCount:         u32,
	UintInstructionCount:        u32,
	StaticFlowControlCount:      u32,
	DynamicFlowControlCount:     u32,
	MacroInstructionCount:       u32,
	ArrayInstructionCount:       u32,
	MovInstructionCount:         u32,
	MovcInstructionCount:        u32,
	ConversionInstructionCount:  u32,
	BitwiseInstructionCount:     u32,
	MinFeatureLevel:             FEATURE_LEVEL,
	RequiredFeatureFlags:        u64,

	Name:                        cstring,
	FunctionParameterCount:      i32,
	HasReturn:                   BOOL,
	Has10Level9VertexShader:     BOOL,
	Has10Level9PixelShader:      BOOL,
}

PARAMETER_DESC :: struct {
	Name:              cstring,
	SemanticName:      cstring,
	Type:              SHADER_VARIABLE_TYPE,
	Class:             SHADER_VARIABLE_CLASS,
	Rows:              u32,
	Columns:           u32,
	InterpolationMode: INTERPOLATION_MODE,
	Flags:             PARAMETER_FLAGS,

	FirstInRegister:   u32,
	FirstInComponent:  u32,
	FirstOutRegister:  u32,
	FirstOutComponent: u32,
}

IShaderReflectionType :: struct {
	vtable: ^IShaderReflectionType_VTable,
}
IShaderReflectionType_VTable :: struct {
	GetDesc:              proc "stdcall" (this: ^IShaderReflectionType, pDesc: ^SHADER_TYPE_DESC) -> HRESULT,
	GetMemberTypeByIndex: proc "stdcall" (this: ^IShaderReflectionType, Index: u32) -> ^IShaderReflectionType,
	GetMemberTypeByName:  proc "stdcall" (this: ^IShaderReflectionType, Name: cstring) -> ^IShaderReflectionType,
	GetMemberTypeName:    proc "stdcall" (this: ^IShaderReflectionType, Index: u32) -> cstring,
	IsEqual:              proc "stdcall" (this: ^IShaderReflectionType, pType: ^IShaderReflectionType) -> HRESULT,
	GetSubType:           proc "stdcall" (this: ^IShaderReflectionType) -> ^IShaderReflectionType,
	GetBaseClass:         proc "stdcall" (this: ^IShaderReflectionType) -> ^IShaderReflectionType,
	GetNumInterfaces:     proc "stdcall" (this: ^IShaderReflectionType) -> u32,
	GetInterfaceByIndex:  proc "stdcall" (this: ^IShaderReflectionType, uIndex: u32) -> ^IShaderReflectionType,
	IsOfType:             proc "stdcall" (this: ^IShaderReflectionType, pType: ^IShaderReflectionType) -> HRESULT,
	ImplementsInterface:  proc "stdcall" (this: ^IShaderReflectionType, pBase: ^IShaderReflectionType) -> HRESULT,
}

IShaderReflectionVariable :: struct {
	vtable: ^IShaderReflectionVariable_VTable,
}
IShaderReflectionVariable_VTable :: struct {
	GetDesc:          proc "stdcall" (this: ^IShaderReflectionVariable, pDesc: ^SHADER_VARIABLE_DESC) -> HRESULT,
	GetType:          proc "stdcall" (this: ^IShaderReflectionVariable) -> ^IShaderReflectionType,
	GetBuffer:        proc "stdcall" (this: ^IShaderReflectionVariable) -> ^IShaderReflectionConstantBuffer,
	GetInterfaceSlot: proc "stdcall" (this: ^IShaderReflectionVariable, uArrayIndex: u32) -> u32,
}

IShaderReflectionConstantBuffer :: struct {
	vtable: ^IShaderReflectionConstantBuffer_VTable,
}
IShaderReflectionConstantBuffer_VTable :: struct {
	GetDesc:            proc "stdcall" (this: ^IShaderReflectionConstantBuffer, pDesc: ^SHADER_BUFFER_DESC) -> HRESULT,
	GetVariableByIndex: proc "stdcall" (this: ^IShaderReflectionConstantBuffer, Index: u32) -> ^IShaderReflectionVariable,
	GetVariableByName:  proc "stdcall" (this: ^IShaderReflectionConstantBuffer, Name: cstring) -> ^IShaderReflectionVariable,
}

IShaderReflection :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12shaderreflection_vtable: ^IShaderReflection_VTable,
}
IShaderReflection_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetDesc:                       proc "stdcall" (this: ^IShaderReflection, pDesc: ^SHADER_DESC) -> HRESULT,
	GetConstantBufferByIndex:      proc "stdcall" (this: ^IShaderReflection, Index: u32) -> ^IShaderReflectionConstantBuffer,
	GetConstantBufferByName:       proc "stdcall" (this: ^IShaderReflection, Name: cstring) -> ^IShaderReflectionConstantBuffer,
	GetResourceBindingDesc:        proc "stdcall" (this: ^IShaderReflection, ResourceIndex: u32, pDesc: ^SHADER_INPUT_BIND_DESC) -> HRESULT,
	GetInputParameterDesc:         proc "stdcall" (this: ^IShaderReflection, ParameterIndex: u32, pDesc: ^SIGNATURE_PARAMETER_DESC) -> HRESULT,
	GetOutputParameterDesc:        proc "stdcall" (this: ^IShaderReflection, ParameterIndex: u32, pDesc: ^SIGNATURE_PARAMETER_DESC) -> HRESULT,
	GetPatchConstantParameterDesc: proc "stdcall" (this: ^IShaderReflection, ParameterIndex: u32, pDesc: ^SIGNATURE_PARAMETER_DESC) -> HRESULT,
	GetVariableByName:             proc "stdcall" (this: ^IShaderReflection, Name: cstring) -> ^IShaderReflectionVariable,
	GetResourceBindingDescByName:  proc "stdcall" (this: ^IShaderReflection, Name: cstring, pDesc: ^SHADER_INPUT_BIND_DESC) -> HRESULT,
	GetMovInstructionCount:        proc "stdcall" (this: ^IShaderReflection) -> u32,
	GetMovcInstructionCount:       proc "stdcall" (this: ^IShaderReflection) -> u32,
	GetConversionInstructionCount: proc "stdcall" (this: ^IShaderReflection) -> u32,
	GetBitwiseInstructionCount:    proc "stdcall" (this: ^IShaderReflection) -> u32,
	GetGSInputPrimitive:           proc "stdcall" (this: ^IShaderReflection) -> PRIMITIVE,
	IsSampleFrequencyShader:       proc "stdcall" (this: ^IShaderReflection) -> BOOL,
	GetNumInterfaceSlots:          proc "stdcall" (this: ^IShaderReflection) -> u32,
	GetMinFeatureLevel:            proc "stdcall" (this: ^IShaderReflection, pLevel: ^FEATURE_LEVEL) -> HRESULT,
	GetThreadGroupSize:            proc "stdcall" (this: ^IShaderReflection, pSizeX: ^u32, pSizeY: ^u32, pSizeZ: ^u32) -> u32,
	GetRequiresFlags:              proc "stdcall" (this: ^IShaderReflection) -> u64,
}

ILibraryReflection :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using id3d12libraryreflection_vtable: ^ILibraryReflection_VTable,
}
ILibraryReflection_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetDesc:            proc "stdcall" (this: ^ILibraryReflection, pDesc: ^LIBRARY_DESC) -> HRESULT,
	GetFunctionByIndex: proc "stdcall" (this: ^ILibraryReflection, FunctionIndex: i32) -> ^IFunctionReflection,
}

IFunctionReflection :: struct {
	vtable: ^IFunctionReflection_VTable,
}
IFunctionReflection_VTable :: struct {
	GetDesc:                      proc "stdcall" (this: ^IFunctionReflection, pDesc: ^FUNCTION_DESC) -> HRESULT,
	GetConstantBufferByIndex:     proc "stdcall" (this: ^IFunctionReflection, BufferIndex: u32) -> ^IShaderReflectionConstantBuffer,
	GetConstantBufferByName:      proc "stdcall" (this: ^IFunctionReflection, Name: cstring) -> ^IShaderReflectionConstantBuffer,
	GetResourceBindingDesc:       proc "stdcall" (this: ^IFunctionReflection, ResourceIndex: u32, pDesc: ^SHADER_INPUT_BIND_DESC) -> HRESULT,
	GetVariableByName:            proc "stdcall" (this: ^IFunctionReflection, Name: cstring) -> ^IShaderReflectionVariable,
	GetResourceBindingDescByName: proc "stdcall" (this: ^IFunctionReflection, Name: cstring, pDesc: ^SHADER_INPUT_BIND_DESC) -> HRESULT,
	GetFunctionParameter:         proc "stdcall" (this: ^IFunctionReflection, ParameterIndex: i32) -> ^IFunctionParameterReflection,
}

IFunctionParameterReflection :: struct {
	vtable: ^IFunctionParameterReflection_VTable,
}
IFunctionParameterReflection_VTable :: struct {
	GetDesc: proc "stdcall" (this: ^IFunctionParameterReflection, pDesc: ^PARAMETER_DESC) -> HRESULT,
}
