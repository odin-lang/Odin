package compress_deflate

import "core:compress"

compress_raw64 :: proc{compress_raw64_to_slice, compress_raw64_to_dynamic}

compress_raw64_bound :: proc(len: int) -> int {
	return compress_raw_bound(len)
}

compress_raw64_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Deflate_Level.Default, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	return deflate_to_dynamic(output, input, level, options, compress_raw64_bound(len(input)), compress_raw64_to_slice)
}

compress_raw64_to_slice :: proc(s: ^Deflate64, output, input: []u8, level := Deflate_Level.Default, options: compress.Options = {}) -> (written: int, err: Error) {
	output := output
	output  = deflate_check_arguments(s, output, compress_raw64_bound(len(input)), options) or_return
	q := output

	s.bit_buffer = 0
	s.bit_count  = 0
	deflate_compress(s, output, &q, input, level, options) or_return
	return deflate_finish_slice(output, q, input, options)
}
