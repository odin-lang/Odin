package compress_deflate

import "core:compress"

inflate64_raw :: proc{inflate64_raw_from_context, inflate64_raw_from_bytes}

inflate64_raw_from_context :: proc(z: ^compress.Context, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	_, err = inflate_to_buffer(z, expected_output_size, max_output_size, D64 = true)
	return
}

inflate64_raw_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return inflate64_raw_from_context(&ctx, expected_output_size, max_output_size, allocator)
}
