//+build !js
package wgpu

BINDINGS_VERSION        :: [4]u8{0, 19, 4, 1}
BINDINGS_VERSION_STRING :: "0.19.4.1"

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
foreign {
	@(link_name="wgpuGenerateReport")
	RawGenerateReport :: proc(instance: Instance, report: ^GlobalReport) ---
	@(link_name="wgpuInstanceEnumerateAdapters")
	RawInstanceEnumerateAdapters :: proc(instance: Instance, /* NULLABLE */ options: /* const */ ^InstanceEnumerateAdapterOptions, adapters: [^]Adapter) -> uint ---

	@(link_name="wgpuQueueSubmitForIndex")
	RawQueueSubmitForIndex :: proc(queue: Queue, commandCount: uint, commands: [^]CommandBuffer) -> SubmissionIndex ---

	// Returns true if the queue is empty, or false if there are more queue submissions still in flight.
	@(link_name="wgpuDevicePoll")
	RawDevicePoll :: proc(device: Device, wait: b32, /* NULLABLE */ wrappedSubmissionIndex: /* const */ ^WrappedSubmissionIndex) -> b32 ---

	SetLogCallback :: proc "odin" (callback: LogCallback) ---

	SetLogLevel :: proc(level: LogLevel) ---

	GetVersion :: proc() -> u32 ---

	RenderPassEncoderSetPushConstants :: proc(encoder: RenderPassEncoder, stages: ShaderStageFlags, offset: u32, sizeBytes: u32, data: cstring) ---

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

DevicePoll :: proc(device: Device, wait: b32) -> (wrappedSubmissionIndex: WrappedSubmissionIndex, ok: bool) {
	ok = bool(RawDevicePoll(device, wait, &wrappedSubmissionIndex))
	return
}

