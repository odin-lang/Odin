package wgpu

import "base:runtime"

BINDINGS_VERSION        :: [4]u8{29, 0, 0, 0}
BINDINGS_VERSION_STRING :: "29.0.0.0"

LogLevel :: enum i32 {
	Off,
	Error,
	Warn,
	Info,
	Debug,
	Trace,
}

InstanceBackend :: enum i32 {
	Vulkan,
	GL,
	Metal,
	DX12,
	// DX11,
	BrowserWebGPU = 5,
}
InstanceBackendFlags :: bit_set[InstanceBackend; Flags]
InstanceBackendFlags_All :: InstanceBackendFlags{}
InstanceBackendFlags_Primary :: InstanceBackendFlags{ .Vulkan, .Metal, .DX12, .BrowserWebGPU }
InstanceBackendFlags_Secondary :: InstanceBackendFlags{ .GL }

InstanceFlag :: enum i32 {
	Debug,
	Validation,
	DiscardHalLabels,
	AllowUnderlyingNoncompliantAdapter,
	GPUBasedValidation,
	ValidationIndirectCall,
	AutomaticTimestampNormalization,
	Default = 24,
	Debugging,
	AdvancedDebugging,
	WithEnv,
}
InstanceFlags :: bit_set[InstanceFlag; Flags]
InstanceFlags_Empty :: InstanceFlags{}

Dx12Compiler :: enum i32 {
	Undefined,
	Fxc,
	Dxc,
}

Gles3MinorVersion :: enum i32 {
	Automatic,
	Version0,
	Version1,
	Version2,
}

PipelineStatisticName :: enum i32 {
	VertexShaderInvocations,
	ClipperInvocations,
	ClipperPrimitivesOut,
	FragmentShaderInvocations,
	ComputeShaderInvocations,
}

DxcMaxShaderModel :: enum i32 {
	V6_0,
	V6_1,
	V6_2,
	V6_3,
	V6_4,
	V6_5,
	V6_6,
	V6_7,
}

GLFenceBehaviour :: enum i32 {
	Normal,
	AutoFinish,
}

Dx12SwapchainKind :: enum i32 {
	Undefined,
	DxgiFromHwnd,
	DxgiFromVisual,
}

NativeDisplayHandleType :: enum i32 {
	None,
	Xlib,
	Xcb,
	Wayland,
}

XlibDisplayHandle :: struct {
	display: rawptr,
	screen: i32,
}

XcbDisplayHandle :: struct {
	connection: rawptr,
	screen: i32,
}

WaylandDisplayHandle :: struct {
	display: rawptr,
}

NativeDisplayHandle :: struct {
	type: NativeDisplayHandleType,
	using data: struct #raw_union {
		xlib: XlibDisplayHandle,
		xcb: XcbDisplayHandle,
		wayland: WaylandDisplayHandle,
	},
}

InstanceExtras :: struct {
	using chain: ChainedStruct,
	backends: InstanceBackendFlags,
	flags: InstanceFlags,
	dx12ShaderCompiler: Dx12Compiler,
	gles3MinorVersion: Gles3MinorVersion,
	glFenceBehaviour: GLFenceBehaviour,
	dxcPath: StringView,
	dcxMaxShaderModel: DxcMaxShaderModel,
	dx12PresentationSystem: Dx12SwapchainKind,
	budgetForDeviceCreation: ^u8,
	budgetForDeviceLoss: ^u8,
	displayHandle: NativeDisplayHandle,
}

DeviceExtras :: struct {
	using chain: ChainedStruct,
	tracePath: StringView,
}

NativeLimits :: struct {
	using chain: ChainedStruct,
	maxImmediateSize: u32,
	maxNonSamplerBindings: u32,
	maxBindingArrayElementsPerShaderStage: u32,
}

PipelineLayoutExtras :: struct {
	using chain: ChainedStruct,
	immediateDataSize: u32,
}

SubmissionIndex :: distinct u64

ShaderDefine :: struct {
	name: StringView,
	value: StringView,
}

ShaderSourceGLSL :: struct {
	using chain: ChainedStruct,
	stage: ShaderStage,
	code: StringView,
	defineCount: uint,
	defines: /* const */ [^]ShaderDefine `fmt:"v,defineCount"`,
}

ShaderModuleDescriptorSpirV :: struct {
	label: StringView,
	sourceSize: u32,
	source: /* const */ [^]u32 `fmt:"v,sourceSize"`,
}

RegistryReport :: struct {
	numAllocated: uint,
	numKeptFromUser: uint,
	numReleasedFromUser: uint,
	elementSize: uint,
}

HubReport :: struct {
	adapters: RegistryReport,
	devices: RegistryReport,
	queues: RegistryReport,
	pipelineLayouts: RegistryReport,
	shaderModules: RegistryReport,
	bindGroupLayouts: RegistryReport,
	bindGroups: RegistryReport,
	commandBuffers: RegistryReport,
	renderBundles: RegistryReport,
	renderPipelines: RegistryReport,
	computePipelines: RegistryReport,
	pipelineCaches: RegistryReport,
	querySets: RegistryReport,
	buffers: RegistryReport,
	textures: RegistryReport,
	textureViews: RegistryReport,
	samplers: RegistryReport,
}

GlobalReport :: struct {
	surfaces: RegistryReport,
	hub: HubReport,
}

InstanceEnumerateAdapterOptions :: struct {
	nextInChain: ^ChainedStruct,
	backends: InstanceBackendFlags,
}

BindGroupEntryExtras :: struct {
	using chain: ChainedStruct,
	buffers: [^]Buffer `fmt:"v,bufferCount"`,
	bufferCount: uint,
	samplers: [^]Sampler `fmt:"v,samplerCount"`,
	samplerCount: uint,
	textureViews: [^]TextureView `fmt:"v,textureViewCount"`,
	textureViewCount: uint,
}

BindGroupLayoutEntryExtras :: struct {
	using chain: ChainedStruct,
	count: u32,
}

QuerySetDescriptorExtras :: struct {
	using chain: ChainedStruct,
	pipelineStatistics: [^]PipelineStatisticName `fmt:"v,pipelineStatisticCount"`,
	pipelineStatisticCount: uint,
}

SurfaceConfigurationExtras :: struct {
	using chain: ChainedStruct,
	desiredMaximumFrameLatency: u32,
}

/**
* Chained in `SurfaceDescriptor` to make a `Surface` wrapping a WinUI [[ SwapChainPanel ; https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/winrt/microsoft.ui.xaml.controls.swapchainpanel ]].
*/
SurfaceSourceSwapChainPanel :: struct {
	using chain: ChainedStruct,
    /**
     * A pointer to the [[ ISwapChainPanelNative ; https://learn.microsoft.com/en-us/windows/windows-app-sdk/api/win32/microsoft.ui.xaml.media.dxinterop/nn-microsoft-ui-xaml-media-dxinterop-iswapchainpanelnative ]]
     * interface of the `SwapChainPanel` that will be wrapped by the `Surface`.
     */
	panelNative: rawptr,
}

PolygonMode :: enum i32 {
	Fill,
	Line,
	Point,
}

PrimitiveStateExtras :: struct {
	using chain: ChainedStruct,
	polygonMode: PolygonMode,
	conservative: b32,
}

LogCallback :: #type proc "c" (level: LogLevel, message: StringView, userdata: rawptr)

// Wrappers

ConvertOdinToWGPULogLevel :: proc(level: runtime.Logger_Level) -> LogLevel {
	switch {
	case level < .Debug:   return .Trace
	case level < .Info:    return .Debug
	case level < .Warning: return .Info
	case level < .Error:   return .Warn
	case:                  return .Error
	}
}

ConvertWGPUToOdinLogLevel :: proc(level: LogLevel) -> runtime.Logger_Level {
	switch level {
	case .Off, .Trace, .Debug: return .Debug
	case .Info:                return .Info
	case .Warn:                return .Warning
	case .Error:               return .Error
	case:                      return .Error
	}
}

ConvertLogLevel :: proc {
	ConvertOdinToWGPULogLevel,
	ConvertWGPUToOdinLogLevel,
}

