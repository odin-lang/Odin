package wgpu

import "core:c"

when WGPU_USE_DAWN {
	DawnProcTable :: rawptr

	ToggleStage :: enum c.int {
		Instance = 0,
		Adapter  = 1,
		Device   = 2,
	}

	ToggleInfo :: struct {
		name:        cstring,
		description: cstring,
		url:         cstring,
		stage:       ToggleStage,
	}

	FeatureState :: enum c.int {
		Stable       = 0,
		Experimental = 1,
	}

	FeatureInfo :: struct {
		name:         cstring,
		description:  cstring,
		url:          cstring,
		featureState: FeatureState,
	}

	BackendValidationLevel :: enum c.int {
		Full     = 0,
		Partial  = 1,
		Disabled = 2,
	}

	DawnInstanceDescriptor :: struct {
		using chain:                       ChainedStruct,
		additionalRuntimeSearchPathsCount: u32,
		additionalRuntimeSearchPaths:      [^]cstring,
		platform:                          rawptr, // dawn::platform::Platform*
		backendValidationLevel:            BackendValidationLevel,
		beginCaptureOnStartup:             b32,
		// TODO: loggingCallbackInfo?
	}

	ExternalImageType :: enum c.int {
		OpaqueFD        = 0,
		DmaBuf          = 1,
		IOSurface       = 2,
		EGLImage        = 3,
		GLTexture       = 4,
		AHardwareBuffer = 5,
	}

	ExternalImageDescriptor :: struct {
		cTextureDescriptor: ^TextureDescriptor,
		isInitialized:      b32,
	}

	ExternalImageExportInfo :: struct {
		isInitialized: b32,
	}

	MemoryUsageInfo :: struct {
		totalUsage:                u64,
		depthStencilTexturesUsage: u64,
		msaaTexturesUsage:         u64,
		msaaTexturesCount:         u64,
		largestMsaaTextureUsage:   u64,
		texturesUsage:             u64,
		buffersUsage:              u64,
	}

	AllocatorMemoryInfo :: struct {
		totalUsedMemory:          u64,
		totalAllocatedMemory:     u64,
		totalLazyAllocatedMemory: u64,
		totalLazyUsedMemory:      u64,
	}
}
