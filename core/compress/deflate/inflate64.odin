package compress_deflate

import "core:compress"
import "core:io"

inflate64_raw :: proc{inflate64_raw_from_context, inflate64_raw_from_bytes}

inflate64_raw_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	p: Inflate_Progress
	inflate_progress_init(&p, z, expected_output_size, options) or_return
	output := inflate_to_buffer(z, expected_output_size, &p, D64 = true) or_return
	return inflate_progress_step(&p, p.bytes_in, i64(len(output)))
}

inflate64_raw_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return inflate64_raw_from_context(&ctx, expected_output_size, options, allocator)
}

inflate64_raw_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	return inflate_stream_to_writer(w, z, .Raw64, expected_output_size, options, allocator)
}
