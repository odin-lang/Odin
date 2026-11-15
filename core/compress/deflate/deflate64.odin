package compress_deflate

deflate64_raw :: proc{deflate64_raw_to_slice, deflate64_raw_to_dynamic}

deflate64_bound :: proc(len: int) -> int {
	return deflate_bound(len)
}

deflate64_raw_to_dynamic :: proc(output: ^[dynamic]u8, input: []u8, level := Deflate_Level.Default, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	return deflate_to_dynamic(output, input, level, deflate64_bound(len(input)), deflate64_raw_to_slice)
}

deflate64_raw_to_slice :: proc(s: ^Deflate64, output, input: []u8, level := Deflate_Level.Default) -> (written: int, err: Error) {
	deflate_check_arguments(s, len(output), deflate64_bound(len(input))) or_return
	s.bit_buffer = 0
	s.bit_count  = 0
	return deflate_compress(s, output, input, level), nil
}
