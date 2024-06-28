package wgpu

import "base:runtime"

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
	DX11,
	BrowserWebGPU,
}
InstanceBackendFlags :: bit_set[InstanceBackend; Flags]
InstanceBackendFlags_All :: InstanceBackendFlags{}
InstanceBackendFlags_Primary :: InstanceBackendFlags{ .Vulkan, .Metal, .DX12, .BrowserWebGPU }
InstanceBackendFlags_Secondary :: InstanceBackendFlags{ .GL, .DX11 }

InstanceFlag :: enum i32 {
	Debug,
	Validation,
	DiscardHalLabels,
}
InstanceFlags :: bit_set[InstanceFlag; Flags]
InstanceFlags_Default :: InstanceFlags{}

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

InstanceExtras :: struct {
	using chain: ChainedStruct,
	backends: InstanceBackendFlags,
	flags: InstanceFlags,
	dx12ShaderCompiler: Dx12Compiler,
	gles3MinorVersion: Gles3MinorVersion,
	dxilPath: cstring,
	dxcPath: cstring,
}

DeviceExtras :: struct {
	using chain: ChainedStruct,
	tracePath: cstring,
}

NativeLimits :: struct {
	maxPushConstantSize: u32,
	maxNonSamplerBindings: u32,
}

RequiredLimitsExtras :: struct {
	using chain: ChainedStruct,
	limits: NativeLimits,
}

SupportedLimitsExtras :: struct {
	using chain: ChainedStructOut,
	limits: NativeLimits,
}

PushConstantRange :: struct {
	stages: ShaderStageFlags,
	start: u32,
	end: u32,
}

PipelineLayoutExtras :: struct {
	using chain: ChainedStruct,
	pushConstantRangeCount: uint,
	pushConstantRanges: [^]PushConstantRange `fmt:"v,pushConstantRangeCount"`,
}

SubmissionIndex :: distinct u64

WrappedSubmissionIndex :: struct {
	queue: Queue,
	submissionIndex: SubmissionIndex,
}

ShaderDefine :: struct {
	name: cstring,
	value: cstring,
}

ShaderModuleGLSLDescriptor :: struct {
	using chain: ChainedStruct,
	stage: ShaderStage,
	code: cstring,
	defineCount: uint,
	defines: [^]ShaderDefine `fmt:"v,defineCount"`,
}

RegistryReport :: struct {
	numAllocated: uint,
	numKeptFromUser: uint,
	numReleasedFromUser: uint,
	numErrors: uint,
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
	querySets: RegistryReport,
	buffers: RegistryReport,
	textures: RegistryReport,
	textureViews: RegistryReport,
	samplers: RegistryReport,
}

GlobalReport :: struct {
	surfaces: RegistryReport,
	backendType: BackendType,
	vulkan: HubReport,
	metal: HubReport,
	dx12: HubReport,
	gl: HubReport,
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
	desiredMaximumFrameLatency: i32,
}

LogCallback :: #type proc "c" (level: LogLevel, message: cstring, userdata: rawptr)

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
