#+build !js
package wgpu

@(link_prefix="wgpu")
foreign libwgpu {
	@(link_name="wgpuGenerateReport")
	RawGenerateReport :: proc(instance: Instance, report: ^GlobalReport) ---
	@(link_name="wgpuInstanceEnumerateAdapters")
	RawInstanceEnumerateAdapters :: proc(instance: Instance, /* NULLABLE */ options: /* const */ ^InstanceEnumerateAdapterOptions, adapters: [^]Adapter) -> uint ---

	@(link_name="wgpuQueueSubmitForIndex")
	RawQueueSubmitForIndex :: proc(queue: Queue, commandCount: uint, commands: [^]CommandBuffer) -> SubmissionIndex ---

	// Returns true if the queue is empty, or false if there are more queue submissions still in flight.
	DevicePoll :: proc(device: Device, wait: b32, /* NULLABLE */ wrappedSubmissionIndex: /* const */ ^SubmissionIndex = nil) -> b32 ---
	DeviceCreateShaderModuleSpirV :: proc(device: Device, descriptor: ^ShaderModuleDescriptorSpirV) -> ShaderModule ---

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
