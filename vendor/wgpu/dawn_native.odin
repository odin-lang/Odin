#+build !js
package wgpu

import "core:c"

when WGPU_USE_DAWN {
	@(link_prefix = "wgpu")
	foreign libwgpu {
		GetProcs :: proc() -> ^DawnProcTable ---

		@(link_name = "wgpuGetTogglesUsed")
		RawGetTogglesUsed :: proc(device: Device) -> [^]cstring ---

		AdapterSetUseTieredLimits :: proc(adapter: Adapter, useTieredLimits: b32) ---
		AdapterSupportsExternalImages :: proc(adapter: Adapter) -> b32 ---
		AdapterCreateDevice :: proc(adapter: Adapter, descriptor: ^DeviceDescriptor = nil) -> Device ---
		AdapterResetInternalDeviceForTesting :: proc(adapter: Adapter) ---

		@(link_name = "wgpuInstanceEnumerateAdapters")
		RawInstanceEnumerateAdapters :: proc(instance: Instance, options: ^RequestAdapterOptions, adapters: [^]Adapter) -> uint ---
		InstanceGetToggleInfo :: proc(instance: Instance, toggleName: cstring) -> ^ToggleInfo ---
		InstanceSetBackendValidationLevel :: proc(instance: Instance, level: BackendValidationLevel) ---
		InstanceGetDeviceCountForTesting :: proc(instance: Instance) -> u64 ---
		InstanceGetDeprecationWarningCountForTesting :: proc(instance: Instance) -> u64 ---
		InstanceDisconnectDawnPlatform :: proc(instance: Instance) ---

		GetLazyClearCountForTesting :: proc(device: Device) -> uint ---
		IsTextureSubresourceInitialized :: proc(texture: Texture, baseMipLevel: u32, levelCount: u32, baseArrayLayer: u32, layerCount: u32, aspect: TextureAspect) -> b32 ---

		@(link_name = "wgpuGetProcMapNamesForTesting")
		RawGetProcMapNamesForTesting :: proc() -> [^]cstring ---

		DeviceTick :: proc(device: Device) -> b32 ---

		EnableErrorInjector :: proc() ---
		DisableErrorInjector :: proc() ---
		ClearErrorInjector :: proc() ---
		AcquireErrorInjectorCallCount :: proc() -> u64 ---
		InjectErrorAt :: proc(index: u64) ---
		CheckIsErrorForTesting :: proc(objectHandle: rawptr) -> b32 ---
		RawGetObjectLabelForTesting :: proc(objectHandle: rawptr) -> cstring ---
		GetAllocatedSizeForTesting :: proc(buffer: Buffer) -> u64 ---

		RawAllToggleInfos :: proc() -> [^]^ToggleInfo ---
		GetFeatureInfo :: proc(feature: FeatureName) -> ^FeatureInfo ---
		DumpMemoryStatistics :: proc(device: Device, dump: rawptr) ---
		ComputeEstimatedMemoryUsageInfo :: proc(device: Device) -> MemoryUsageInfo ---
		GetAllocatorMemoryInfo :: proc(device: Device) -> AllocatorMemoryInfo ---
		ReduceMemoryUsage :: proc(device: Device) -> b32 ---
		PerformIdleTasks :: proc(device: Device) ---
		IsDeviceLost :: proc(device: Device) -> b32 ---

		RenderPassEncoderMultiDrawIndirect :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count: u32) ---
		RenderPassEncoderMultiDrawIndexedIndirect :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count: u32) ---

		RenderPassEncoderMultiDrawIndirectCount :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count_buffer: Buffer, count_buffer_offset: u64, max_count: u32) ---
		RenderPassEncoderMultiDrawIndexedIndirectCount :: proc(encoder: RenderPassEncoder, buffer: Buffer, offset: u64, count_buffer: Buffer, count_buffer_offset: u64, max_count: u32) ---
	}

	GetTogglesUsed :: proc(device: Device, allocator := context.allocator) -> (toggles: []string) {
		raw_toggles := RawGetTogglesUsed(device)
		if raw_toggles == nil {
			return
		}
		count := 0
		for raw_toggles[count] != nil {
			count += 1
		}
		toggles = make([]string, count, allocator)
		for i in 0 ..< count {
			toggles[i] = string(raw_toggles[i])
		}
		return
	}

	GetObjectLabelForTesting :: proc(objectHandle: rawptr) -> string {
		cstr := RawGetObjectLabelForTesting(objectHandle)
		if cstr == nil {
			return ""
		}
		return string(cstr)
	}

	AllToggleInfos :: proc(allocator := context.allocator) -> (infos: []^ToggleInfo) {
		raw_infos := RawAllToggleInfos()
		if raw_infos == nil {
			return
		}
		count := 0
		for raw_infos[count] != nil {
			count += 1
		}
		infos = make([]^ToggleInfo, count, allocator)
		for i in 0 ..< count {
			infos[i] = raw_infos[i]
		}
		return
	}

	GetProcMapNamesForTesting :: proc(allocator := context.allocator) -> (names: []string) {
		raw_names := RawGetProcMapNamesForTesting()
		if raw_names == nil {
			return
		}
		count := 0
		for raw_names[count] != nil {
			count += 1
		}
		names = make([]string, count, allocator)
		for i in 0 ..< count {
			names[i] = string(raw_names[i])
		}
		return
	}

	// polyfill for wgpu_native DevicePoll
	DevicePoll :: proc(
		device: Device,
		wait: b32,
		/* NULLABLE */
		submissionIndex: rawptr = nil,
	) -> b32 {
		DeviceTick(device)
		return true
	}
}
