package directx_dxgi

foreign import dxgi {
	"system:dxgi.lib",
	"system:user32.lib",
	"system:gdi32.lib",
}

import win32 "core:sys/windows"

LUID                :: win32.LUID
IID                 :: win32.GUID
UUID                :: win32.GUID
GUID                :: win32.GUID
HANDLE              :: win32.HANDLE
HRESULT             :: win32.HRESULT
HMONITOR            :: win32.HMONITOR
HWND                :: win32.HWND
HMODULE             :: win32.HMODULE
HDC                 :: win32.HANDLE
BOOL                :: win32.BOOL
LARGE_INTEGER       :: win32.LARGE_INTEGER
SIZE_T              :: win32.SIZE_T
ULONG               :: win32.ULONG
LONG                :: win32.LONG
RECT                :: win32.RECT
POINT               :: win32.POINT
SIZE                :: win32.SIZE

IUnknown :: struct {
	using _iunknown_vtable: ^IUnknown_VTable,
}
IUnknown_VTable :: struct {
	QueryInterface: proc "stdcall" (this: ^IUnknown, riid: ^IID, ppvObject: ^rawptr) -> HRESULT,
	AddRef:         proc "stdcall" (this: ^IUnknown) -> ULONG,
	Release:        proc "stdcall" (this: ^IUnknown) -> ULONG,
}

@(default_calling_convention="stdcall")
foreign dxgi {
	CreateDXGIFactory      :: proc(riid: ^IID, ppFactory: rawptr) -> HRESULT ---
	CreateDXGIFactory1     :: proc(riid: ^IID, ppFactory: rawptr) -> HRESULT ---
	CreateDXGIFactory2     :: proc(Flags: u32, riid: ^IID, ppFactory: rawptr) -> HRESULT ---
	DXGIGetDebugInterface1 :: proc(Flags: u32, riid: ^IID, pDebug: rawptr) -> HRESULT ---
}

STANDARD_MULTISAMPLE_QUALITY_PATTERN :: 0xffffffff
CENTER_MULTISAMPLE_QUALITY_PATTERN :: 0xfffffffe
FORMAT_DEFINED :: 1
_FACDXGI :: 0x87a

CPU_ACCESS :: enum u32 {
	NONE       =  0,
	DYNAMIC    =  1,
	READ_WRITE =  2,
	SCRATCH    =  3,
	FIELD      = 15,
}

USAGE :: enum u32 { // TODO: convert to bit_set
	SHADER_INPUT         = 0x00000010,
	RENDER_TARGET_OUTPUT = 0x00000020,
	BACK_BUFFER          = 0x00000040,
	SHARED               = 0x00000080,
	READ_ONLY            = 0x00000100,
	DISCARD_ON_PRESENT   = 0x00000200,
	UNORDERED_ACCESS     = 0x00000400,
}

RESOURCE_PRIORITY :: enum u32 {
	MINIMUM = 0x28000000,
	LOW     = 0x50000000,
	NORMAL  = 0x78000000,
	HIGH    = 0xa0000000,
	MAXIMUM = 0xc8000000,
}

MAP :: enum u32 { // TODO: convert to bit_set
	READ    = 1,
	WRITE   = 2,
	DISCARD = 4,
}

ENUM_MODES :: enum u32 { // TODO: convert to bit_set
	INTERLACED      = 1,
	SCALING         = 2,
	STEREO          = 4,
	DISABLED_STEREO = 8,
}

MAX_SWAP_CHAIN_BUFFERS :: 16
PRESENT :: enum u32 { // TODO: convert to bit_set
	TEST                  = 0x00000001,
	DO_NOT_SEQUENCE       = 0x00000002,
	RESTART               = 0x00000004,
	DO_NOT_WAIT           = 0x00000008,
	STEREO_PREFER_RIGHT   = 0x00000010,
	STEREO_TEMPORARY_MONO = 0x00000020,
	RESTRICT_TO_OUTPUT    = 0x00000040,
	USE_DURATION          = 0x00000100,
	ALLOW_TEARING         = 0x00000200,
}

MWA :: enum u32 { // TODO: convert to bit_set
	NO_WINDOW_CHANGES = 1 << 0,
	NO_ALT_ENTER      = 1 << 1,
	NO_PRINT_SCREEN   = 1 << 2,
	VALID             = 0x7,
}

SHARED_RESOURCE_READ  :: 0x80000000
SHARED_RESOURCE_WRITE :: 1
CREATE_FACTORY_DEBUG  :: 0x1

RATIONAL :: struct {
	Numerator:   u32,
	Denominator: u32,
}

SAMPLE_DESC :: struct {
	Count:   u32,
	Quality: u32,
}

COLOR_SPACE_TYPE :: enum i32 {
	RGB_FULL_G22_NONE_P709           = 0,
	RGB_FULL_G10_NONE_P709           = 1,
	RGB_STUDIO_G22_NONE_P709         = 2,
	RGB_STUDIO_G22_NONE_P2020        = 3,
	RESERVED                         = 4,
	YCBCR_FULL_G22_NONE_P709_X601    = 5,
	YCBCR_STUDIO_G22_LEFT_P601       = 6,
	YCBCR_FULL_G22_LEFT_P601         = 7,
	YCBCR_STUDIO_G22_LEFT_P709       = 8,
	YCBCR_FULL_G22_LEFT_P709         = 9,
	YCBCR_STUDIO_G22_LEFT_P2020      = 10,
	YCBCR_FULL_G22_LEFT_P2020        = 11,
	RGB_FULL_G2084_NONE_P2020        = 12,
	YCBCR_STUDIO_G2084_LEFT_P2020    = 13,
	RGB_STUDIO_G2084_NONE_P2020      = 14,
	YCBCR_STUDIO_G22_TOPLEFT_P2020   = 15,
	YCBCR_STUDIO_G2084_TOPLEFT_P2020 = 16,
	RGB_FULL_G22_NONE_P2020          = 17,
	YCBCR_STUDIO_GHLG_TOPLEFT_P2020  = 18,
	YCBCR_FULL_GHLG_TOPLEFT_P2020    = 19,
	RGB_STUDIO_G24_NONE_P709         = 20,
	RGB_STUDIO_G24_NONE_P2020        = 21,
	YCBCR_STUDIO_G24_LEFT_P709       = 22,
	YCBCR_STUDIO_G24_LEFT_P2020      = 23,
	YCBCR_STUDIO_G24_TOPLEFT_P2020   = 24,
	CUSTOM                           = -1,
}

FORMAT :: enum i32 {
	UNKNOWN                                 = 0,
	R32G32B32A32_TYPELESS                   = 1,
	R32G32B32A32_FLOAT                      = 2,
	R32G32B32A32_UINT                       = 3,
	R32G32B32A32_SINT                       = 4,
	R32G32B32_TYPELESS                      = 5,
	R32G32B32_FLOAT                         = 6,
	R32G32B32_UINT                          = 7,
	R32G32B32_SINT                          = 8,
	R16G16B16A16_TYPELESS                   = 9,
	R16G16B16A16_FLOAT                      = 10,
	R16G16B16A16_UNORM                      = 11,
	R16G16B16A16_UINT                       = 12,
	R16G16B16A16_SNORM                      = 13,
	R16G16B16A16_SINT                       = 14,
	R32G32_TYPELESS                         = 15,
	R32G32_FLOAT                            = 16,
	R32G32_UINT                             = 17,
	R32G32_SINT                             = 18,
	R32G8X24_TYPELESS                       = 19,
	D32_FLOAT_S8X24_UINT                    = 20,
	R32_FLOAT_X8X24_TYPELESS                = 21,
	X32_TYPELESS_G8X24_UINT                 = 22,
	R10G10B10A2_TYPELESS                    = 23,
	R10G10B10A2_UNORM                       = 24,
	R10G10B10A2_UINT                        = 25,
	R11G11B10_FLOAT                         = 26,
	R8G8B8A8_TYPELESS                       = 27,
	R8G8B8A8_UNORM                          = 28,
	R8G8B8A8_UNORM_SRGB                     = 29,
	R8G8B8A8_UINT                           = 30,
	R8G8B8A8_SNORM                          = 31,
	R8G8B8A8_SINT                           = 32,
	R16G16_TYPELESS                         = 33,
	R16G16_FLOAT                            = 34,
	R16G16_UNORM                            = 35,
	R16G16_UINT                             = 36,
	R16G16_SNORM                            = 37,
	R16G16_SINT                             = 38,
	R32_TYPELESS                            = 39,
	D32_FLOAT                               = 40,
	R32_FLOAT                               = 41,
	R32_UINT                                = 42,
	R32_SINT                                = 43,
	R24G8_TYPELESS                          = 44,
	D24_UNORM_S8_UINT                       = 45,
	R24_UNORM_X8_TYPELESS                   = 46,
	X24_TYPELESS_G8_UINT                    = 47,
	R8G8_TYPELESS                           = 48,
	R8G8_UNORM                              = 49,
	R8G8_UINT                               = 50,
	R8G8_SNORM                              = 51,
	R8G8_SINT                               = 52,
	R16_TYPELESS                            = 53,
	R16_FLOAT                               = 54,
	D16_UNORM                               = 55,
	R16_UNORM                               = 56,
	R16_UINT                                = 57,
	R16_SNORM                               = 58,
	R16_SINT                                = 59,
	R8_TYPELESS                             = 60,
	R8_UNORM                                = 61,
	R8_UINT                                 = 62,
	R8_SNORM                                = 63,
	R8_SINT                                 = 64,
	A8_UNORM                                = 65,
	R1_UNORM                                = 66,
	R9G9B9E5_SHAREDEXP                      = 67,
	R8G8_B8G8_UNORM                         = 68,
	G8R8_G8B8_UNORM                         = 69,
	BC1_TYPELESS                            = 70,
	BC1_UNORM                               = 71,
	BC1_UNORM_SRGB                          = 72,
	BC2_TYPELESS                            = 73,
	BC2_UNORM                               = 74,
	BC2_UNORM_SRGB                          = 75,
	BC3_TYPELESS                            = 76,
	BC3_UNORM                               = 77,
	BC3_UNORM_SRGB                          = 78,
	BC4_TYPELESS                            = 79,
	BC4_UNORM                               = 80,
	BC4_SNORM                               = 81,
	BC5_TYPELESS                            = 82,
	BC5_UNORM                               = 83,
	BC5_SNORM                               = 84,
	B5G6R5_UNORM                            = 85,
	B5G5R5A1_UNORM                          = 86,
	B8G8R8A8_UNORM                          = 87,
	B8G8R8X8_UNORM                          = 88,
	R10G10B10_XR_BIAS_A2_UNORM              = 89,
	B8G8R8A8_TYPELESS                       = 90,
	B8G8R8A8_UNORM_SRGB                     = 91,
	B8G8R8X8_TYPELESS                       = 92,
	B8G8R8X8_UNORM_SRGB                     = 93,
	BC6H_TYPELESS                           = 94,
	BC6H_UF16                               = 95,
	BC6H_SF16                               = 96,
	BC7_TYPELESS                            = 97,
	BC7_UNORM                               = 98,
	BC7_UNORM_SRGB                          = 99,
	AYUV                                    = 100,
	Y410                                    = 101,
	Y416                                    = 102,
	NV12                                    = 103,
	P010                                    = 104,
	P016                                    = 105,
	_420_OPAQUE                             = 106,
	YUY2                                    = 107,
	Y210                                    = 108,
	Y216                                    = 109,
	NV11                                    = 110,
	AI44                                    = 111,
	IA44                                    = 112,
	P8                                      = 113,
	A8P8                                    = 114,
	B4G4R4A4_UNORM                          = 115,

	P208                                    = 130,
	V208                                    = 131,
	V408                                    = 132,

	SAMPLER_FEEDBACK_MIN_MIP_OPAQUE         = 189,
	SAMPLER_FEEDBACK_MIP_REGION_USED_OPAQUE = 190,

	FORCE_UINT                              = -1,
}

RGB :: struct {
	Red:   f32,
	Green: f32,
	Blue:  f32,
}

D3DCOLORVALUE :: struct {
	r: f32,
	g: f32,
	b: f32,
	a: f32,
}

RGBA :: D3DCOLORVALUE

GAMMA_CONTROL :: struct {
	Scale:      RGB,
	Offset:     RGB,
	GammaCurve: [1025]RGB,
}

GAMMA_CONTROL_CAPABILITIES :: struct {
	ScaleAndOffsetSupported: BOOL,
	MaxConvertedValue:       f32,
	MinConvertedValue:       f32,
	NumGammaControlPoints:   u32,
	ControlPointPositions:   [1025]f32,
}

MODE_SCANLINE_ORDER :: enum i32 {
	UNSPECIFIED       = 0,
	PROGRESSIVE       = 1,
	UPPER_FIELD_FIRST = 2,
	LOWER_FIELD_FIRST = 3,
}

MODE_SCALING :: enum i32 {
	UNSPECIFIED = 0,
	CENTERED    = 1,
	STRETCHED   = 2,
}

MODE_ROTATION :: enum i32 {
	UNSPECIFIED = 0,
	IDENTITY    = 1,
	ROTATE90    = 2,
	ROTATE180   = 3,
	ROTATE270   = 4,
}

MODE_DESC :: struct {
	Width:            u32,
	Height:           u32,
	RefreshRate:      RATIONAL,
	Format:           FORMAT,
	ScanlineOrdering: MODE_SCANLINE_ORDER,
	Scaling:          MODE_SCALING,
}

JPEG_DC_HUFFMAN_TABLE :: struct {
	CodeCounts: [12]u8,
	CodeValues: [12]u8,
}

JPEG_AC_HUFFMAN_TABLE :: struct {
	CodeCounts: [16]u8,
	CodeValues: [162]u8,
}

JPEG_QUANTIZATION_TABLE :: struct {
	Elements: [64]u8,
}

FRAME_STATISTICS :: struct {
	PresentCount:        u32,
	PresentRefreshCount: u32,
	SyncRefreshCount:    u32,
	SyncQPCTime:         LARGE_INTEGER,
	SyncGPUTime:         LARGE_INTEGER,
}

MAPPED_RECT :: struct {
	Pitch: i32,
	pBits: [^]u8,
}

ADAPTER_DESC :: struct {
	Description:           [128]i16,
	VendorId:              u32,
	DeviceId:              u32,
	SubSysId:              u32,
	Revision:              u32,
	DedicatedVideoMemory:  SIZE_T,
	DedicatedSystemMemory: SIZE_T,
	SharedSystemMemory:    SIZE_T,
	AdapterLuid:           LUID,
}

OUTPUT_DESC :: struct {
	DeviceName:         [32]i16,
	DesktopCoordinates: RECT,
	AttachedToDesktop:  BOOL,
	Rotation:           MODE_ROTATION,
	Monitor:            HMONITOR,
}

SHARED_RESOURCE :: struct {
	Handle: HANDLE,
}

RESIDENCY :: enum i32 {
	FULLY_RESIDENT            = 1,
	RESIDENT_IN_SHARED_MEMORY = 2,
	EVICTED_TO_DISK           = 3,
}

SURFACE_DESC :: struct {
	Width:      u32,
	Height:     u32,
	Format:     FORMAT,
	SampleDesc: SAMPLE_DESC,
}

SWAP_EFFECT :: enum i32 {
	DISCARD         = 0,
	SEQUENTIAL      = 1,
	FLIP_SEQUENTIAL = 3,
	FLIP_DISCARD    = 4,
}

SWAP_CHAIN_FLAG :: enum u32 { // TODO: convert to bit_set
	NONPREROTATED                          = 0x1,
	ALLOW_MODE_SWITCH                      = 0x2,
	GDI_COMPATIBLE                         = 0x4,
	RESTRICTED_CONTENT                     = 0x8,
	RESTRICT_SHARED_RESOURCE_DRIVER        = 0x10,
	DISPLAY_ONLY                           = 0x20,
	FRAME_LATENCY_WAITABLE_OBJECT          = 0x40,
	FOREGROUND_LAYER                       = 0x80,
	FULLSCREEN_VIDEO                       = 0x100,
	YUV_VIDEO                              = 0x200,
	HW_PROTECTED                           = 0x400,
	ALLOW_TEARING                          = 0x800,
	RESTRICTED_TO_ALL_HOLOGRAPHIC_DISPLAYS = 0x1000,
}

SWAP_CHAIN_DESC :: struct {
	BufferDesc:   MODE_DESC,
	SampleDesc:   SAMPLE_DESC,
	BufferUsage:  USAGE,
	BufferCount:  u32,
	OutputWindow: HWND,
	Windowed:     BOOL,
	SwapEffect:   SWAP_EFFECT,
	Flags:        u32,
}


IObject_UUID_STRING :: "AEC22FB8-76F3-4639-9BE0-28EB43A67A2E"
IObject_UUID := &IID{0xAEC22FB8, 0x76F3, 0x4639, {0x9B, 0xE0, 0x28, 0xEB, 0x43, 0xA6, 0x7A, 0x2E}}
IObject :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using vtable: ^IObject_VTable,
}
IObject_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	SetPrivateData:          proc "stdcall" (this: ^IObject, Name: ^GUID, DataSize: u32, pData: rawptr) -> HRESULT,
	SetPrivateDataInterface: proc "stdcall" (this: ^IObject, Name: ^GUID, pUnknown: ^IUnknown) -> HRESULT,
	GetPrivateData:          proc "stdcall" (this: ^IObject, Name: ^GUID, pDataSize: ^u32, pData: rawptr) -> HRESULT,
	GetParent:               proc "stdcall" (this: ^IObject, riid: ^IID, ppParent: ^rawptr) -> HRESULT,
}

IDeviceSubObject_UUID_STRING :: "3D3E0379-F9DE-4D58-BB6C-18D62992F1A6"
IDeviceSubObject_UUID := &IID{0x3D3E0379, 0xF9DE, 0x4D58, {0xBB, 0x6C, 0x18, 0xD6, 0x29, 0x92, 0xF1, 0xA6}}
IDeviceSubObject :: struct #raw_union {
	#subtype idxgiobject: IObject,
	using idxgidevicesubobject_vtable: ^IDeviceSubObject_VTable,
}
IDeviceSubObject_VTable :: struct {
	using idxgiobject_vtable: IObject_VTable,
	GetDevice: proc "stdcall" (this: ^IDeviceSubObject, riid: ^IID, ppDevice: ^rawptr) -> HRESULT,
}

IResource_UUID_STRING :: "035F3AB4-482E-4E50-B41F-8A7F8BD8960B"
IResource_UUID := &IID{0x035F3AB4, 0x482E, 0x4E50, {0xB4, 0x1F, 0x8A, 0x7F, 0x8B, 0xD8, 0x96, 0x0B}}
IResource :: struct #raw_union {
	#subtype idxgidevicesubobject: IDeviceSubObject,
	using idxgiresource_vtable: ^IResource_VTable,
}
IResource_VTable :: struct {
	using idxgidevicesubobject_vtable: IDeviceSubObject_VTable,
	GetSharedHandle:     proc "stdcall" (this: ^IResource, pSharedHandle: ^HANDLE) -> HRESULT,
	GetUsage:            proc "stdcall" (this: ^IResource, pUsage: ^USAGE) -> HRESULT,
	SetEvictionPriority: proc "stdcall" (this: ^IResource, EvictionPriority: u32) -> HRESULT,
	GetEvictionPriority: proc "stdcall" (this: ^IResource, pEvictionPriority: ^u32) -> HRESULT,
}

IKeyedMutex_UUID_STRING :: "9D8E1289-D7B3-465F-8126-250E349AF85D"
IKeyedMutex_UUID := &IID{0x9D8E1289, 0xD7B3, 0x465F, {0x81, 0x26, 0x25, 0x0E, 0x34, 0x9A, 0xF8, 0x5D}}
IKeyedMutex :: struct #raw_union {
	#subtype idxgidevicesubobject: IDeviceSubObject,
	using idxgikeyedmutex_vtable: ^IKeyedMutex_VTable,
}
IKeyedMutex_VTable :: struct {
	using idxgidevicesubobject_vtable: IDeviceSubObject_VTable,
	AcquireSync: proc "stdcall" (this: ^IKeyedMutex, Key: u64, dwMilliseconds: u32) -> HRESULT,
	ReleaseSync: proc "stdcall" (this: ^IKeyedMutex, Key: u64) -> HRESULT,
}

ISurface_UUID_STRING :: "CAFCB56C-6AC3-4889-BF47-9E23BBD260EC"
ISurface_UUID := &IID{0xCAFCB56C, 0x6AC3, 0x4889, {0xBF, 0x47, 0x9E, 0x23, 0xBB, 0xD2, 0x60, 0xEC}}
ISurface :: struct #raw_union {
	#subtype idxgidevicesubobject: IDeviceSubObject,
	using idxgisurface_vtable: ^ISurface_VTable,
}
ISurface_VTable :: struct {
	using idxgidevicesubobject_vtable: IDeviceSubObject_VTable,
	GetDesc: proc "stdcall" (this: ^ISurface, pDesc: ^SURFACE_DESC) -> HRESULT,
	Map:     proc "stdcall" (this: ^ISurface, pLockedRect: ^MAPPED_RECT, MapFlags: u32) -> HRESULT,
	Unmap:   proc "stdcall" (this: ^ISurface) -> HRESULT,
}

ISurface1_UUID_STRING :: "4AE63092-6327-4C1B-80AE-BFE12EA32B86"
ISurface1_UUID := &IID{0x4AE63092, 0x6327, 0x4C1B, {0x80, 0xAE, 0xBF, 0xE1, 0x2E, 0xA3, 0x2B, 0x86}}
ISurface1 :: struct #raw_union {
	#subtype idxgisurface: ISurface,
	using idxgisurface1_vtable: ^ISurface1_VTable,
}
ISurface1_VTable :: struct {
	using idxgisurface_vtable: ISurface_VTable,
	GetDC:     proc "stdcall" (this: ^ISurface1, Discard: BOOL, phdc: ^HDC) -> HRESULT,
	ReleaseDC: proc "stdcall" (this: ^ISurface1, pDirtyRect: ^RECT) -> HRESULT,
}

IAdapter_UUID_STRING :: "2411E7E1-12AC-4CCF-BD14-9798E8534DC0"
IAdapter_UUID := &IID{0x2411E7E1, 0x12AC, 0x4CCF, {0xBD, 0x14, 0x97, 0x98, 0xE8, 0x53, 0x4D, 0xC0}}
IAdapter :: struct #raw_union {
	#subtype idxgiobject: IObject,
	using idxgiadapter_vtable: ^IAdapter_VTable,
}
IAdapter_VTable :: struct {
	using idxgiobject_vtable: IObject_VTable,
	EnumOutputs:           proc "stdcall" (this: ^IAdapter, Output: u32, ppOutput: ^^IOutput) -> HRESULT,
	GetDesc:               proc "stdcall" (this: ^IAdapter, pDesc: ^ADAPTER_DESC) -> HRESULT,
	CheckInterfaceSupport: proc "stdcall" (this: ^IAdapter, InterfaceName: ^GUID, pUMDVersion: ^LARGE_INTEGER) -> HRESULT,
}

IOutput_UUID_STRING :: "AE02EEDB-C735-4690-8D52-5A8DC20213AA"
IOutput_UUID := &IID{0xAE02EEDB, 0xC735, 0x4690, {0x8D, 0x52, 0x5A, 0x8D, 0xC2, 0x02, 0x13, 0xAA}}
IOutput :: struct #raw_union {
	#subtype idxgiobject: IObject,
	using idxgioutput_vtable: ^IOutput_VTable,
}
IOutput_VTable :: struct {
	using idxgiobject_vtable: IObject_VTable,
	GetDesc:                     proc "stdcall" (this: ^IOutput, pDesc: ^OUTPUT_DESC) -> HRESULT,
	GetDisplayModeList:          proc "stdcall" (this: ^IOutput, EnumFormat: FORMAT, Flags: u32, pNumModes: ^u32, pDesc: ^MODE_DESC) -> HRESULT,
	FindClosestMatchingMode:     proc "stdcall" (this: ^IOutput, pModeToMatch: ^MODE_DESC, pClosestMatch: ^MODE_DESC, pConcernedDevice: ^IUnknown) -> HRESULT,
	WaitForVBlank:               proc "stdcall" (this: ^IOutput) -> HRESULT,
	TakeOwnership:               proc "stdcall" (this: ^IOutput, pDevice: ^IUnknown, Exclusive: BOOL) -> HRESULT,
	ReleaseOwnership:            proc "stdcall" (this: ^IOutput),
	GetGammaControlCapabilities: proc "stdcall" (this: ^IOutput, pGammaCaps: ^GAMMA_CONTROL_CAPABILITIES) -> HRESULT,
	SetGammaControl:             proc "stdcall" (this: ^IOutput, pArray: ^GAMMA_CONTROL) -> HRESULT,
	GetGammaControl:             proc "stdcall" (this: ^IOutput, pArray: ^GAMMA_CONTROL) -> HRESULT,
	SetDisplaySurface:           proc "stdcall" (this: ^IOutput, pScanoutSurface: ^ISurface) -> HRESULT,
	GetDisplaySurfaceData:       proc "stdcall" (this: ^IOutput, pDestination: ^ISurface) -> HRESULT,
	GetFrameStatistics:          proc "stdcall" (this: ^IOutput, pStats: ^FRAME_STATISTICS) -> HRESULT,
}

ISwapChain_UUID_STRING :: "310D36A0-D2E7-4C0A-AA04-6A9D23B8886A"
ISwapChain_UUID := &IID{0x310D36A0, 0xD2E7, 0x4C0A, {0xAA, 0x04, 0x6A, 0x9D, 0x23, 0xB8, 0x88, 0x6A}}
ISwapChain :: struct #raw_union {
	#subtype idxgidevicesubobject: IDeviceSubObject,
	using idxgiswapchain_vtable: ^ISwapChain_VTable,
}
ISwapChain_VTable :: struct {
	using idxgidevicesubobject_vtable: IDeviceSubObject_VTable,
	Present:             proc "stdcall" (this: ^ISwapChain, SyncInterval: u32, Flags: u32) -> HRESULT,
	GetBuffer:           proc "stdcall" (this: ^ISwapChain, Buffer: u32, riid: ^IID, ppSurface: ^rawptr) -> HRESULT,
	SetFullscreenState:  proc "stdcall" (this: ^ISwapChain, Fullscreen: BOOL, pTarget: ^IOutput) -> HRESULT,
	GetFullscreenState:  proc "stdcall" (this: ^ISwapChain, pFullscreen: ^BOOL, ppTarget: ^^IOutput) -> HRESULT,
	GetDesc:             proc "stdcall" (this: ^ISwapChain, pDesc: ^SWAP_CHAIN_DESC) -> HRESULT,
	ResizeBuffers:       proc "stdcall" (this: ^ISwapChain, BufferCount: u32, Width: u32, Height: u32, NewFormat: FORMAT, SwapChainFlags: u32) -> HRESULT,
	ResizeTarget:        proc "stdcall" (this: ^ISwapChain, pNewTargetParameters: ^MODE_DESC) -> HRESULT,
	GetContainingOutput: proc "stdcall" (this: ^ISwapChain, ppOutput: ^^IOutput) -> HRESULT,
	GetFrameStatistics:  proc "stdcall" (this: ^ISwapChain, pStats: ^FRAME_STATISTICS) -> HRESULT,
	GetLastPresentCount: proc "stdcall" (this: ^ISwapChain, pLastPresentCount: ^u32) -> HRESULT,
}

IFactory_UUID_STRING :: "7B7166EC-21C7-44AE-B21A-C9AE321AE369"
IFactory_UUID := &IID{0x7B7166EC, 0x21C7, 0x44AE, {0xB2, 0x1A, 0xC9, 0xAE, 0x32, 0x1A, 0xE3, 0x69}}
IFactory :: struct #raw_union {
	#subtype idxgiobject: IObject,
	using idxgifactory_vtable: ^IFactory_VTable,
}
IFactory_VTable :: struct {
	using idxgiobject_vtable: IObject_VTable,
	EnumAdapters:          proc "stdcall" (this: ^IFactory, Adapter: u32, ppAdapter: ^^IAdapter) -> HRESULT,
	MakeWindowAssociation: proc "stdcall" (this: ^IFactory, WindowHandle: HWND, Flags: u32) -> HRESULT,
	GetWindowAssociation:  proc "stdcall" (this: ^IFactory, pWindowHandle: ^HWND) -> HRESULT,
	CreateSwapChain:       proc "stdcall" (this: ^IFactory, pDevice: ^IUnknown, pDesc: ^SWAP_CHAIN_DESC, ppSwapChain: ^^ISwapChain) -> HRESULT,
	CreateSoftwareAdapter: proc "stdcall" (this: ^IFactory, Module: HMODULE, ppAdapter: ^^IAdapter) -> HRESULT,
}
IDevice_UUID_STRING :: "54EC77FA-1377-44E6-8C32-88FD5F44C84C"
IDevice_UUID := &IID{0x54EC77FA, 0x1377, 0x44E6, {0x8C, 0x32, 0x88, 0xFD, 0x5F, 0x44, 0xC8, 0x4C}}
IDevice :: struct #raw_union {
	#subtype idxgiobject: IObject,
	using idxgidevice_vtable: ^IDevice_VTable,
}
IDevice_VTable :: struct {
	using idxgiobject_vtable: IObject_VTable,
	GetAdapter:             proc "stdcall" (this: ^IDevice, pAdapter: ^^IAdapter) -> HRESULT,
	CreateSurface:          proc "stdcall" (this: ^IDevice, pDesc: ^SURFACE_DESC, NumSurfaces: u32, Usage: USAGE, pSharedResource: ^SHARED_RESOURCE, ppSurface: ^^ISurface) -> HRESULT,
	QueryResourceResidency: proc "stdcall" (this: ^IDevice, ppResources: ^^IUnknown, pResidencyStatus: ^RESIDENCY, NumResources: u32) -> HRESULT,
	SetGPUThreadPriority:   proc "stdcall" (this: ^IDevice, Priority: i32) -> HRESULT,
	GetGPUThreadPriority:   proc "stdcall" (this: ^IDevice, pPriority: ^i32) -> HRESULT,
}
ADAPTER_FLAG :: enum u32 { // TODO: convert to bit_set
	NONE        = 0x0,
	REMOTE      = 0x1,
	SOFTWARE    = 0x2,
	FORCE_DWORD = 0xffffffff,
}

ADAPTER_DESC1 :: struct {
	Description:           [128]i16,
	VendorId:              u32,
	DeviceId:              u32,
	SubSysId:              u32,
	Revision:              u32,
	DedicatedVideoMemory:  SIZE_T,
	DedicatedSystemMemory: SIZE_T,
	SharedSystemMemory:    SIZE_T,
	AdapterLuid:           LUID,
	Flags:                 u32,
}

DISPLAY_COLOR_SPACE :: struct {
	PrimaryCoordinates: [8][2]f32,
	WhitePoints:        [16][2]f32,
}


IFactory1_UUID_STRING :: "770AAE78-F26F-4DBA-A829-253C83D1B387"
IFactory1_UUID := &IID{0x770AAE78, 0xF26F, 0x4DBA, {0xA8, 0x29, 0x25, 0x3C, 0x83, 0xD1, 0xB3, 0x87}}
IFactory1 :: struct #raw_union {
	#subtype idxgifactory: IFactory,
	using idxgifactory1_vtable: ^IFactory1_VTable,
}
IFactory1_VTable :: struct {
	using idxgifactory_vtable: IFactory_VTable,
	EnumAdapters1: proc "stdcall" (this: ^IFactory1, Adapter: u32, ppAdapter: ^^IAdapter1) -> HRESULT,
	IsCurrent:     proc "stdcall" (this: ^IFactory1) -> BOOL,
}

IAdapter1_UUID_STRING :: "29038F61-3839-4626-91FD-086879011A05"
IAdapter1_UUID := &IID{0x29038F61, 0x3839, 0x4626, {0x91, 0xFD, 0x08, 0x68, 0x79, 0x01, 0x1A, 0x05}}
IAdapter1 :: struct #raw_union {
	#subtype idxgiadapter: IAdapter,
	using idxgiadapter1_vtable: ^IAdapter1_VTable,
}
IAdapter1_VTable :: struct {
	using idxgiadapter_vtable: IAdapter_VTable,
	GetDesc1: proc "stdcall" (this: ^IAdapter1, pDesc: ^ADAPTER_DESC1) -> HRESULT,
}

IDevice1_UUID_STRING :: "77DB970F-6276-48BA-BA28-070143B4392C"
IDevice1_UUID := &IID{0x77DB970F, 0x6276, 0x48BA, {0xBA, 0x28, 0x07, 0x01, 0x43, 0xB4, 0x39, 0x2C}}
IDevice1 :: struct #raw_union {
	#subtype idxgidevice: IDevice,
	using idxgidevice1_vtable: ^IDevice1_VTable,
}
IDevice1_VTable :: struct {
	using idxgidevice_vtable: IDevice_VTable,
	SetMaximumFrameLatency: proc "stdcall" (this: ^IDevice1, MaxLatency: u32) -> HRESULT,
	GetMaximumFrameLatency: proc "stdcall" (this: ^IDevice1, pMaxLatency: ^u32) -> HRESULT,
}

IDisplayControl_UUID_STRING :: "EA9DBF1A-C88E-4486-854A-98AA0138F30C"
IDisplayControl_UUID := &IID{0xEA9DBF1A, 0xC88E, 0x4486, {0x85, 0x4A, 0x98, 0xAA, 0x01, 0x38, 0xF3, 0x0C}}
IDisplayControl :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxgidisplaycontrol_vtable: ^IDisplayControl_VTable,
}
IDisplayControl_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	IsStereoEnabled:  proc "stdcall" (this: ^IDisplayControl) -> BOOL,
	SetStereoEnabled: proc "stdcall" (this: ^IDisplayControl, enabled: BOOL),
}
OUTDUPL_MOVE_RECT :: struct {
	SourcePoint:     POINT,
	DestinationRect: RECT,
}

OUTDUPL_DESC :: struct {
	ModeDesc:                   MODE_DESC,
	Rotation:                   MODE_ROTATION,
	DesktopImageInSystemMemory: BOOL,
}

OUTDUPL_POINTER_POSITION :: struct {
	Position: POINT,
	Visible:  BOOL,
}

OUTDUPL_POINTER_SHAPE_TYPE :: enum i32 {
	MONOCHROME   = 1,
	COLOR        = 2,
	MASKED_COLOR = 4,
}

OUTDUPL_POINTER_SHAPE_INFO :: struct {
	Type:    u32,
	Width:   u32,
	Height:  u32,
	Pitch:   u32,
	HotSpot: POINT,
}

OUTDUPL_FRAME_INFO :: struct {
	LastPresentTime:           LARGE_INTEGER,
	LastMouseUpdateTime:       LARGE_INTEGER,
	AccumulatedFrames:         u32,
	RectsCoalesced:            BOOL,
	ProtectedContentMaskedOut: BOOL,
	PointerPosition:           OUTDUPL_POINTER_POSITION,
	TotalMetadataBufferSize:   u32,
	PointerShapeBufferSize:    u32,
}


IOutputDuplication_UUID_STRING :: "191CFAC3-A341-470D-B26E-A864F428319C"
IOutputDuplication_UUID := &IID{0x191CFAC3, 0xA341, 0x470D, {0xB2, 0x6E, 0xA8, 0x64, 0xF4, 0x28, 0x31, 0x9C}}
IOutputDuplication :: struct #raw_union {
	#subtype idxgiobject: IObject,
	using idxgioutputduplication_vtable: ^IOutputDuplication_VTable,
}
IOutputDuplication_VTable :: struct {
	using idxgiobject_vtable: IObject_VTable,
	GetDesc:              proc "stdcall" (this: ^IOutputDuplication, pDesc: ^OUTDUPL_DESC),
	AcquireNextFrame:     proc "stdcall" (this: ^IOutputDuplication, TimeoutInMilliseconds: u32, pFrameInfo: ^OUTDUPL_FRAME_INFO, ppDesktopResource: ^^IResource) -> HRESULT,
	GetFrameDirtyRects:   proc "stdcall" (this: ^IOutputDuplication, DirtyRectsBufferSize: u32, pDirtyRectsBuffer: ^RECT, pDirtyRectsBufferSizeRequired: ^u32) -> HRESULT,
	GetFrameMoveRects:    proc "stdcall" (this: ^IOutputDuplication, MoveRectsBufferSize: u32, pMoveRectBuffer: ^OUTDUPL_MOVE_RECT, pMoveRectsBufferSizeRequired: ^u32) -> HRESULT,
	GetFramePointerShape: proc "stdcall" (this: ^IOutputDuplication, PointerShapeBufferSize: u32, pPointerShapeBuffer: rawptr, pPointerShapeBufferSizeRequired: ^u32, pPointerShapeInfo: ^OUTDUPL_POINTER_SHAPE_INFO) -> HRESULT,
	MapDesktopSurface:    proc "stdcall" (this: ^IOutputDuplication, pLockedRect: ^MAPPED_RECT) -> HRESULT,
	UnMapDesktopSurface:  proc "stdcall" (this: ^IOutputDuplication) -> HRESULT,
	ReleaseFrame:         proc "stdcall" (this: ^IOutputDuplication) -> HRESULT,
}
ALPHA_MODE :: enum i32 {
	UNSPECIFIED   = 0,
	PREMULTIPLIED = 1,
	STRAIGHT      = 2,
	IGNORE        = 3,
	FORCE_DWORD   = -1,
}


ISurface2_UUID_STRING :: "ABA496DD-B617-4CB8-A866-BC44D7EB1FA2"
ISurface2_UUID := &IID{0xABA496DD, 0xB617, 0x4CB8, {0xA8, 0x66, 0xBC, 0x44, 0xD7, 0xEB, 0x1F, 0xA2}}
ISurface2 :: struct #raw_union {
	#subtype idxgisurface1: ISurface1,
	using idxgisurface2_vtable: ^ISurface2_VTable,
}
ISurface2_VTable :: struct {
	using idxgisurface1_vtable: ISurface1_VTable,
	GetResource: proc "stdcall" (this: ^ISurface2, riid: ^IID, ppParentResource: ^rawptr, pSubresourceIndex: ^u32) -> HRESULT,
}

IResource1_UUID_STRING :: "30961379-4609-4A41-998E-54FE567EE0C1"
IResource1_UUID := &IID{0x30961379, 0x4609, 0x4A41, {0x99, 0x8E, 0x54, 0xFE, 0x56, 0x7E, 0xE0, 0xC1}}
IResource1 :: struct #raw_union {
	#subtype idxgiresource: IResource,
	using idxgiresource1_vtable: ^IResource1_VTable,
}
IResource1_VTable :: struct {
	using idxgiresource_vtable: IResource_VTable,
	CreateSubresourceSurface: proc "stdcall" (this: ^IResource1, index: u32, ppSurface: ^^ISurface2) -> HRESULT,
	CreateSharedHandle:       proc "stdcall" (this: ^IResource1, pAttributes: ^win32.SECURITY_ATTRIBUTES, dwAccess: u32, lpName: ^i16, pHandle: ^HANDLE) -> HRESULT,
}
OFFER_RESOURCE_PRIORITY :: enum i32 {
	LOW    = 1,
	NORMAL = 2,
	HIGH   = 3,
}


IDevice2_UUID_STRING :: "05008617-FBFD-4051-A790-144884B4F6A9"
IDevice2_UUID := &IID{0x05008617, 0xFBFD, 0x4051, {0xA7, 0x90, 0x14, 0x48, 0x84, 0xB4, 0xF6, 0xA9}}
IDevice2 :: struct #raw_union {
	#subtype idxgidevice1: IDevice1,
	using idxgidevice2_vtable: ^IDevice2_VTable,
}
IDevice2_VTable :: struct {
	using idxgidevice1_vtable: IDevice1_VTable,
	OfferResources:   proc "stdcall" (this: ^IDevice2, NumResources: u32, ppResources: ^^IResource, Priority: OFFER_RESOURCE_PRIORITY) -> HRESULT,
	ReclaimResources: proc "stdcall" (this: ^IDevice2, NumResources: u32, ppResources: ^^IResource, pDiscarded: ^BOOL) -> HRESULT,
	EnqueueSetEvent:  proc "stdcall" (this: ^IDevice2, hEvent: HANDLE) -> HRESULT,
}
MODE_DESC1 :: struct {
	Width:            u32,
	Height:           u32,
	RefreshRate:      RATIONAL,
	Format:           FORMAT,
	ScanlineOrdering: MODE_SCANLINE_ORDER,
	Scaling:          MODE_SCALING,
	Stereo:           BOOL,
}

SCALING :: enum i32 {
	STRETCH              = 0,
	NONE                 = 1,
	ASPECT_RATIO_STRETCH = 2,
}

SWAP_CHAIN_DESC1 :: struct {
	Width:       u32,
	Height:      u32,
	Format:      FORMAT,
	Stereo:      BOOL,
	SampleDesc:  SAMPLE_DESC,
	BufferUsage: USAGE,
	BufferCount: u32,
	Scaling:     SCALING,
	SwapEffect:  SWAP_EFFECT,
	AlphaMode:   ALPHA_MODE,
	Flags:       u32,
}

SWAP_CHAIN_FULLSCREEN_DESC :: struct {
	RefreshRate:      RATIONAL,
	ScanlineOrdering: MODE_SCANLINE_ORDER,
	Scaling:          MODE_SCALING,
	Windowed:         BOOL,
}

PRESENT_PARAMETERS :: struct {
	DirtyRectsCount: u32,

	pDirtyRects:     [^]RECT,
	pScrollRect:     ^RECT,
	pScrollOffset:   ^POINT,
}


ISwapChain1_UUID_STRING :: "790A45F7-0D42-4876-983A-0A55CFE6F4AA"
ISwapChain1_UUID := &IID{0x790A45F7, 0x0D42, 0x4876, {0x98, 0x3A, 0x0A, 0x55, 0xCF, 0xE6, 0xF4, 0xAA}}
ISwapChain1 :: struct #raw_union {
	#subtype idxgiswapchain: ISwapChain,
	using idxgiswapchain1_vtable: ^ISwapChain1_VTable,
}
ISwapChain1_VTable :: struct {
	using idxgiswapchain_vtable: ISwapChain_VTable,
	GetDesc1:                 proc "stdcall" (this: ^ISwapChain1, pDesc: ^SWAP_CHAIN_DESC1) -> HRESULT,
	GetFullscreenDesc:        proc "stdcall" (this: ^ISwapChain1, pDesc: ^SWAP_CHAIN_FULLSCREEN_DESC) -> HRESULT,
	GetHwnd:                  proc "stdcall" (this: ^ISwapChain1, pHwnd: ^HWND) -> HRESULT,
	GetCoreWindow:            proc "stdcall" (this: ^ISwapChain1, refiid: ^IID, ppUnk: ^rawptr) -> HRESULT,
	Present1:                 proc "stdcall" (this: ^ISwapChain1, SyncInterval: u32, PresentFlags: u32, pPresentParameters: ^PRESENT_PARAMETERS) -> HRESULT,
	IsTemporaryMonoSupported: proc "stdcall" (this: ^ISwapChain1) -> BOOL,
	GetRestrictToOutput:      proc "stdcall" (this: ^ISwapChain1, ppRestrictToOutput: ^^IOutput) -> HRESULT,
	SetBackgroundColor:       proc "stdcall" (this: ^ISwapChain1, pColor: ^RGBA) -> HRESULT,
	GetBackgroundColor:       proc "stdcall" (this: ^ISwapChain1, pColor: ^RGBA) -> HRESULT,
	SetRotation:              proc "stdcall" (this: ^ISwapChain1, Rotation: MODE_ROTATION) -> HRESULT,
	GetRotation:              proc "stdcall" (this: ^ISwapChain1, pRotation: ^MODE_ROTATION) -> HRESULT,
}

IFactory2_UUID_STRING :: "50C83A1C-E072-4C48-87B0-3630FA36A6D0"
IFactory2_UUID := &IID{0x50C83A1C, 0xE072, 0x4C48, {0x87, 0xB0, 0x36, 0x30, 0xFA, 0x36, 0xA6, 0xD0}}
IFactory2 :: struct #raw_union {
	#subtype idxgifactory1: IFactory1,
	using idxgifactory2_vtable: ^IFactory2_VTable,
}
IFactory2_VTable :: struct {
	using idxgifactory1_vtable: IFactory1_VTable,
	IsWindowedStereoEnabled:       proc "stdcall" (this: ^IFactory2) -> BOOL,
	CreateSwapChainForHwnd:        proc "stdcall" (this: ^IFactory2, pDevice: ^IUnknown, hWnd: HWND, pDesc: ^SWAP_CHAIN_DESC1, pFullscreenDesc: ^SWAP_CHAIN_FULLSCREEN_DESC, pRestrictToOutput: ^IOutput, ppSwapChain: ^^ISwapChain1) -> HRESULT,
	CreateSwapChainForCoreWindow:  proc "stdcall" (this: ^IFactory2, pDevice: ^IUnknown, pWindow: ^IUnknown, pDesc: ^SWAP_CHAIN_DESC1, pRestrictToOutput: ^IOutput, ppSwapChain: ^^ISwapChain1) -> HRESULT,
	GetSharedResourceAdapterLuid:  proc "stdcall" (this: ^IFactory2, hResource: HANDLE, pLuid: ^LUID) -> HRESULT,
	RegisterStereoStatusWindow:    proc "stdcall" (this: ^IFactory2, WindowHandle: HWND, wMsg: u32, pdwCookie: ^u32) -> HRESULT,
	RegisterStereoStatusEvent:     proc "stdcall" (this: ^IFactory2, hEvent: HANDLE, pdwCookie: ^u32) -> HRESULT,
	UnregisterStereoStatus:        proc "stdcall" (this: ^IFactory2, dwCookie: u32),
	RegisterOcclusionStatusWindow: proc "stdcall" (this: ^IFactory2, WindowHandle: HWND, wMsg: u32, pdwCookie: ^u32) -> HRESULT,
	RegisterOcclusionStatusEvent:  proc "stdcall" (this: ^IFactory2, hEvent: HANDLE, pdwCookie: ^u32) -> HRESULT,
	UnregisterOcclusionStatus:     proc "stdcall" (this: ^IFactory2, dwCookie: u32),
	CreateSwapChainForComposition: proc "stdcall" (this: ^IFactory2, pDevice: ^IUnknown, pDesc: ^SWAP_CHAIN_DESC1, pRestrictToOutput: ^IOutput, ppSwapChain: ^^ISwapChain1) -> HRESULT,
}
GRAPHICS_PREEMPTION_GRANULARITY :: enum i32 {
	DMA_BUFFER_BOUNDARY  = 0,
	PRIMITIVE_BOUNDARY   = 1,
	TRIANGLE_BOUNDARY    = 2,
	PIXEL_BOUNDARY       = 3,
	INSTRUCTION_BOUNDARY = 4,
}

COMPUTE_PREEMPTION_GRANULARITY :: enum i32 {
	DMA_BUFFER_BOUNDARY   = 0,
	DISPATCH_BOUNDARY     = 1,
	THREAD_GROUP_BOUNDARY = 2,
	THREAD_BOUNDARY       = 3,
	INSTRUCTION_BOUNDARY  = 4,
}

ADAPTER_DESC2 :: struct {
	Description:                   [128]i16,
	VendorId:                      u32,
	DeviceId:                      u32,
	SubSysId:                      u32,
	Revision:                      u32,
	DedicatedVideoMemory:          SIZE_T,
	DedicatedSystemMemory:         SIZE_T,
	SharedSystemMemory:            SIZE_T,
	AdapterLuid:                   LUID,
	Flags:                         u32,
	GraphicsPreemptionGranularity: GRAPHICS_PREEMPTION_GRANULARITY,
	ComputePreemptionGranularity:  COMPUTE_PREEMPTION_GRANULARITY,
}


IAdapter2_UUID_STRING :: "0AA1AE0A-FA0E-4B84-8644-E05FF8E5ACB5"
IAdapter2_UUID := &IID{0x0AA1AE0A, 0xFA0E, 0x4B84, {0x86, 0x44, 0xE0, 0x5F, 0xF8, 0xE5, 0xAC, 0xB5}}
IAdapter2 :: struct #raw_union {
	#subtype idxgiadapter1: IAdapter1,
	using idxgiadapter2_vtable: ^IAdapter2_VTable,
}
IAdapter2_VTable :: struct {
	using idxgiadapter1_vtable: IAdapter1_VTable,
	GetDesc2: proc "stdcall" (this: ^IAdapter2, pDesc: ^ADAPTER_DESC2) -> HRESULT,
}

IOutput1_UUID_STRING :: "00CDDEA8-939B-4B83-A340-A685226666CC"
IOutput1_UUID := &IID{0x00CDDEA8, 0x939B, 0x4B83, {0xA3, 0x40, 0xA6, 0x85, 0x22, 0x66, 0x66, 0xCC}}
IOutput1 :: struct #raw_union {
	#subtype idxgioutput: IOutput,
	using idxgioutput1_vtable: ^IOutput1_VTable,
}
IOutput1_VTable :: struct {
	using idxgioutput_vtable: IOutput_VTable,
	GetDisplayModeList1:      proc "stdcall" (this: ^IOutput1, EnumFormat: FORMAT, Flags: u32, pNumModes: ^u32, pDesc: ^MODE_DESC1) -> HRESULT,
	FindClosestMatchingMode1: proc "stdcall" (this: ^IOutput1, pModeToMatch: ^MODE_DESC1, pClosestMatch: ^MODE_DESC1, pConcernedDevice: ^IUnknown) -> HRESULT,
	GetDisplaySurfaceData1:   proc "stdcall" (this: ^IOutput1, pDestination: ^IResource) -> HRESULT,
	DuplicateOutput:          proc "stdcall" (this: ^IOutput1, pDevice: ^IUnknown, ppOutputDuplication: ^^IOutputDuplication) -> HRESULT,
}
IDevice3_UUID_STRING :: "6007896C-3244-4AFD-BF18-A6D3BEDA5023"
IDevice3_UUID := &IID{0x6007896C, 0x3244, 0x4AFD, {0xBF, 0x18, 0xA6, 0xD3, 0xBE, 0xDA, 0x50, 0x23}}
IDevice3 :: struct #raw_union {
	#subtype idxgidevice2: IDevice2,
	using idxgidevice3_vtable: ^IDevice3_VTable,
}
IDevice3_VTable :: struct {
	using idxgidevice2_vtable: IDevice2_VTable,
	Trim: proc "stdcall" (this: ^IDevice3),
}
MATRIX_3X2_F :: struct {
	_11: f32,
	_12: f32,
	_21: f32,
	_22: f32,
	_31: f32,
	_32: f32,
}


ISwapChain2_UUID_STRING :: "A8BE2AC4-199F-4946-B331-79599FB98DE7"
ISwapChain2_UUID := &IID{0xA8BE2AC4, 0x199F, 0x4946, {0xB3, 0x31, 0x79, 0x59, 0x9F, 0xB9, 0x8D, 0xE7}}
ISwapChain2 :: struct #raw_union {
	#subtype idxgiswapchain1: ISwapChain1,
	using idxgiswapchain2_vtable: ^ISwapChain2_VTable,
}
ISwapChain2_VTable :: struct {
	using idxgiswapchain1_vtable: ISwapChain1_VTable,
	SetSourceSize:                 proc "stdcall" (this: ^ISwapChain2, Width: u32, Height: u32) -> HRESULT,
	GetSourceSize:                 proc "stdcall" (this: ^ISwapChain2, pWidth: ^u32, pHeight: ^u32) -> HRESULT,
	SetMaximumFrameLatency:        proc "stdcall" (this: ^ISwapChain2, MaxLatency: u32) -> HRESULT,
	GetMaximumFrameLatency:        proc "stdcall" (this: ^ISwapChain2, pMaxLatency: ^u32) -> HRESULT,
	GetFrameLatencyWaitableObject: proc "stdcall" (this: ^ISwapChain2) -> HANDLE,
	SetMatrixTransform:            proc "stdcall" (this: ^ISwapChain2, pMatrix: ^MATRIX_3X2_F) -> HRESULT,
	GetMatrixTransform:            proc "stdcall" (this: ^ISwapChain2, pMatrix: ^MATRIX_3X2_F) -> HRESULT,
}

IOutput2_UUID_STRING :: "595E39D1-2724-4663-99B1-DA969DE28364"
IOutput2_UUID := &IID{0x595E39D1, 0x2724, 0x4663, {0x99, 0xB1, 0xDA, 0x96, 0x9D, 0xE2, 0x83, 0x64}}
IOutput2 :: struct #raw_union {
	#subtype idxgioutput1: IOutput1,
	using idxgioutput2_vtable: ^IOutput2_VTable,
}
IOutput2_VTable :: struct {
	using idxgioutput1_vtable: IOutput1_VTable,
	SupportsOverlays: proc "stdcall" (this: ^IOutput2) -> BOOL,
}

IFactory3_UUID_STRING :: "25483823-CD46-4C7D-86CA-47AA95B837BD"
IFactory3_UUID := &IID{0x25483823, 0xCD46, 0x4C7D, {0x86, 0xCA, 0x47, 0xAA, 0x95, 0xB8, 0x37, 0xBD}}
IFactory3 :: struct #raw_union {
	#subtype idxgifactory2: IFactory2,
	using idxgifactory3_vtable: ^IFactory3_VTable,
}
IFactory3_VTable :: struct {
	using idxgifactory2_vtable: IFactory2_VTable,
	GetCreationFlags: proc "stdcall" (this: ^IFactory3) -> u32,
}
DECODE_SWAP_CHAIN_DESC :: struct {
	Flags: u32,
}

MULTIPLANE_OVERLAY_YCbCr_FLAGS :: enum u32 { // TODO: convert to bit_set
	NOMINAL_RANGE = 0x1,
	BT709         = 0x2,
	xvYCC         = 0x4,
}


IDecodeSwapChain_UUID_STRING :: "2633066B-4514-4C7A-8FD8-12EA98059D18"
IDecodeSwapChain_UUID := &IID{0x2633066B, 0x4514, 0x4C7A, {0x8F, 0xD8, 0x12, 0xEA, 0x98, 0x05, 0x9D, 0x18}}
IDecodeSwapChain :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxgidecodeswapchain_vtable: ^IDecodeSwapChain_VTable,
}
IDecodeSwapChain_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	PresentBuffer: proc "stdcall" (this: ^IDecodeSwapChain, BufferToPresent: u32, SyncInterval: u32, Flags: u32) -> HRESULT,
	SetSourceRect: proc "stdcall" (this: ^IDecodeSwapChain, pRect: ^RECT) -> HRESULT,
	SetTargetRect: proc "stdcall" (this: ^IDecodeSwapChain, pRect: ^RECT) -> HRESULT,
	SetDestSize:   proc "stdcall" (this: ^IDecodeSwapChain, Width: u32, Height: u32) -> HRESULT,
	GetSourceRect: proc "stdcall" (this: ^IDecodeSwapChain, pRect: ^RECT) -> HRESULT,
	GetTargetRect: proc "stdcall" (this: ^IDecodeSwapChain, pRect: ^RECT) -> HRESULT,
	GetDestSize:   proc "stdcall" (this: ^IDecodeSwapChain, pWidth: ^u32, pHeight: ^u32) -> HRESULT,
	SetColorSpace: proc "stdcall" (this: ^IDecodeSwapChain, ColorSpace: MULTIPLANE_OVERLAY_YCbCr_FLAGS) -> HRESULT,
	GetColorSpace: proc "stdcall" (this: ^IDecodeSwapChain) -> MULTIPLANE_OVERLAY_YCbCr_FLAGS,
}

IFactoryMedia_UUID_STRING :: "41E7D1F2-A591-4F7B-A2E5-FA9C843E1C12"
IFactoryMedia_UUID := &IID{0x41E7D1F2, 0xA591, 0x4F7B, {0xA2, 0xE5, 0xFA, 0x9C, 0x84, 0x3E, 0x1C, 0x12}}
IFactoryMedia :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxgifactorymedia_vtable: ^IFactoryMedia_VTable,
}
IFactoryMedia_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	CreateSwapChainForCompositionSurfaceHandle: proc "stdcall" (this: ^IFactoryMedia, pDevice: ^IUnknown, hSurface: HANDLE, pDesc: ^SWAP_CHAIN_DESC1, pRestrictToOutput: ^IOutput, ppSwapChain: ^^ISwapChain1) -> HRESULT,
	CreateDecodeSwapChainForCompositionSurfaceHandle: proc "stdcall" (this: ^IFactoryMedia, pDevice: ^IUnknown, hSurface: HANDLE, pDesc: ^DECODE_SWAP_CHAIN_DESC, pYuvDecodeBuffers: ^IResource, pRestrictToOutput: ^IOutput, ppSwapChain: ^^IDecodeSwapChain) -> HRESULT,
}
FRAME_PRESENTATION_MODE :: enum i32 {
	COMPOSED            = 0,
	OVERLAY             = 1,
	NONE                = 2,
	COMPOSITION_FAILURE = 3,
}

FRAME_STATISTICS_MEDIA :: struct {
	PresentCount:            u32,
	PresentRefreshCount:     u32,
	SyncRefreshCount:        u32,
	SyncQPCTime:             LARGE_INTEGER,
	SyncGPUTime:             LARGE_INTEGER,
	CompositionMode:         FRAME_PRESENTATION_MODE,
	ApprovedPresentDuration: u32,
}


ISwapChainMedia_UUID_STRING :: "DD95B90B-F05F-4F6A-BD65-25BFB264BD84"
ISwapChainMedia_UUID := &IID{0xDD95B90B, 0xF05F, 0x4F6A, {0xBD, 0x65, 0x25, 0xBF, 0xB2, 0x64, 0xBD, 0x84}}
ISwapChainMedia :: struct #raw_union {
	#subtype iunknown: IUnknown,
	using idxgiswapchainmedia_vtable: ^ISwapChainMedia_VTable,
}
ISwapChainMedia_VTable :: struct {
	using iunknown_vtable: IUnknown_VTable,
	GetFrameStatisticsMedia:     proc "stdcall" (this: ^ISwapChainMedia, pStats: ^FRAME_STATISTICS_MEDIA) -> HRESULT,
	SetPresentDuration:          proc "stdcall" (this: ^ISwapChainMedia, Duration: u32) -> HRESULT,
	CheckPresentDurationSupport: proc "stdcall" (this: ^ISwapChainMedia, DesiredPresentDuration: u32, pClosestSmallerPresentDuration: ^u32, pClosestLargerPresentDuration: ^u32) -> HRESULT,
}
OVERLAY_SUPPORT_FLAG :: enum u32 { // TODO: convert to bit_set
	DIRECT  = 0x1,
	SCALING = 0x2,
}


IOutput3_UUID_STRING :: "8A6BB301-7E7E-41F4-A8E0-5B32F7F99B18"
IOutput3_UUID := &IID{0x8A6BB301, 0x7E7E, 0x41F4, {0xA8, 0xE0, 0x5B, 0x32, 0xF7, 0xF9, 0x9B, 0x18}}
IOutput3 :: struct #raw_union {
	#subtype idxgioutput2: IOutput2,
	using idxgioutput3_vtable: ^IOutput3_VTable,
}
IOutput3_VTable :: struct {
	using idxgioutput2_vtable: IOutput2_VTable,
	CheckOverlaySupport: proc "stdcall" (this: ^IOutput3, EnumFormat: FORMAT, pConcernedDevice: ^IUnknown, pFlags: ^u32) -> HRESULT,
}
SWAP_CHAIN_COLOR_SPACE_SUPPORT_FLAG :: enum u32 { // TODO: convert to bit_set
	PRESENT         = 0x1,
	OVERLAY_PRESENT = 0x2,
}


ISwapChain3_UUID_STRING :: "94D99BDB-F1F8-4AB0-B236-7DA0170EDAB1"
ISwapChain3_UUID := &IID{0x94D99BDB, 0xF1F8, 0x4AB0, {0xB2, 0x36, 0x7D, 0xA0, 0x17, 0x0E, 0xDA, 0xB1}}
ISwapChain3 :: struct #raw_union {
	#subtype idxgiswapchain2: ISwapChain2,
	using idxgiswapchain3_vtable: ^ISwapChain3_VTable,
}
ISwapChain3_VTable :: struct {
	using idxgiswapchain2_vtable: ISwapChain2_VTable,
	GetCurrentBackBufferIndex: proc "stdcall" (this: ^ISwapChain3) -> u32,
	CheckColorSpaceSupport:    proc "stdcall" (this: ^ISwapChain3, ColorSpace: COLOR_SPACE_TYPE, pColorSpaceSupport: ^u32) -> HRESULT,
	SetColorSpace1:            proc "stdcall" (this: ^ISwapChain3, ColorSpace: COLOR_SPACE_TYPE) -> HRESULT,
	ResizeBuffers1:            proc "stdcall" (this: ^ISwapChain3, BufferCount: u32, Width: u32, Height: u32, Format: FORMAT, SwapChainFlags: u32, pCreationNodeMask: ^u32, ppPresentQueue: ^^IUnknown) -> HRESULT,
}
OVERLAY_COLOR_SPACE_SUPPORT_FLAG :: enum u32 { // TODO: convert to bit_set
	PRESENT = 0x1,
}


IOutput4_UUID_STRING :: "DC7DCA35-2196-414D-9F53-617884032A60"
IOutput4_UUID := &IID{0xDC7DCA35, 0x2196, 0x414D, {0x9F, 0x53, 0x61, 0x78, 0x84, 0x03, 0x2A, 0x60}}
IOutput4 :: struct #raw_union {
	#subtype idxgioutput3: IOutput3,
	using idxgioutput4_vtable: ^IOutput4_VTable,
}
IOutput4_VTable :: struct {
	using idxgioutput3_vtable: IOutput3_VTable,
	CheckOverlayColorSpaceSupport: proc "stdcall" (this: ^IOutput4, Format: FORMAT, ColorSpace: COLOR_SPACE_TYPE, pConcernedDevice: ^IUnknown, pFlags: ^u32) -> HRESULT,
}

IFactory4_UUID_STRING :: "1BC6EA02-EF36-464F-BF0C-21CA39E5168A"
IFactory4_UUID := &IID{0x1BC6EA02, 0xEF36, 0x464F, {0xBF, 0x0C, 0x21, 0xCA, 0x39, 0xE5, 0x16, 0x8A}}
IFactory4 :: struct #raw_union {
	#subtype idxgifactory3: IFactory3,
	using idxgifactory4_vtable: ^IFactory4_VTable,
}
IFactory4_VTable :: struct {
	using idxgifactory3_vtable: IFactory3_VTable,
	EnumAdapterByLuid: proc "stdcall" (this: ^IFactory4, AdapterLuid: LUID, riid: ^IID, ppvAdapter: ^rawptr) -> HRESULT,
	EnumWarpAdapter:   proc "stdcall" (this: ^IFactory4, riid: ^IID, ppvAdapter: ^rawptr) -> HRESULT,
}
MEMORY_SEGMENT_GROUP :: enum i32 {
	LOCAL     = 0,
	NON_LOCAL = 1,
}

QUERY_VIDEO_MEMORY_INFO :: struct {
	Budget:                  u64,
	CurrentUsage:            u64,
	AvailableForReservation: u64,
	CurrentReservation:      u64,
}


IAdapter3_UUID_STRING :: "645967A4-1392-4310-A798-8053CE3E93FD"
IAdapter3_UUID := &IID{0x645967A4, 0x1392, 0x4310, {0xA7, 0x98, 0x80, 0x53, 0xCE, 0x3E, 0x93, 0xFD}}
IAdapter3 :: struct #raw_union {
	#subtype idxgiadapter2: IAdapter2,
	using idxgiadapter3_vtable: ^IAdapter3_VTable,
}
IAdapter3_VTable :: struct {
	using idxgiadapter2_vtable: IAdapter2_VTable,
	RegisterHardwareContentProtectionTeardownStatusEvent: proc "stdcall" (this: ^IAdapter3, hEvent: HANDLE, pdwCookie: ^u32) -> HRESULT,
	UnregisterHardwareContentProtectionTeardownStatus:    proc "stdcall" (this: ^IAdapter3, dwCookie: u32),
	QueryVideoMemoryInfo:                                 proc "stdcall" (this: ^IAdapter3, NodeIndex: u32, MemorySegmentGroup: MEMORY_SEGMENT_GROUP, pVideoMemoryInfo: ^QUERY_VIDEO_MEMORY_INFO) -> HRESULT,
	SetVideoMemoryReservation:                            proc "stdcall" (this: ^IAdapter3, NodeIndex: u32, MemorySegmentGroup: MEMORY_SEGMENT_GROUP, Reservation: u64) -> HRESULT,
	RegisterVideoMemoryBudgetChangeNotificationEvent:     proc "stdcall" (this: ^IAdapter3, hEvent: HANDLE, pdwCookie: ^u32) -> HRESULT,
	UnregisterVideoMemoryBudgetChangeNotification:        proc "stdcall" (this: ^IAdapter3, dwCookie: u32),
}