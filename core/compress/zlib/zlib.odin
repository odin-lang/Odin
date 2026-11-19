package compress_zlib

/*
	Copyright 2021-2026 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.
		Ginger Bill:     Cosmetic changes.
*/

import "core:compress"
import "core:compress/deflate"

import "core:bytes"

/*
	`zlib.inflate` decompresses a ZLIB stream passed in as a `[]u8` or `io.Stream`.
	Returns: `compress.Error`.
*/

Error         :: compress.Error
General_Error :: compress.General_Error
ZLIB_Error    :: compress.ZLIB_Error
Deflate_Error :: compress.Deflate_Error

@(deprecated="Use `deflate.decompress_zlib` or `deflate.decompress_raw` from `core:compress/deflate`")
inflate_from_context :: proc(ctx: ^compress.Context, raw := false, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	if raw {
		return deflate.decompress_raw_from_context(ctx, expected_output_size, allocator=allocator)
	}
	return deflate.decompress_zlib_from_context(ctx, expected_output_size, allocator=allocator)
}

@(deprecated="Use `deflate.decompress_raw` from `core:compress/deflate`")
inflate_raw :: proc(z: ^compress.Context, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	return deflate.decompress_raw_from_context(z, expected_output_size, allocator=allocator)
}

@(deprecated="Use `deflate.decompress_zlib` or `deflate.decompress_raw` from `core:compress/deflate`")
inflate_from_byte_array :: proc(data: []u8, output: ^bytes.Buffer, raw := false, expected_output_size := -1) -> (err: Error) {
	data := data
	ctx  := compress.init_context_from_slice(&data, output=&output.buf)
	if raw {
		return deflate.decompress_raw_from_context(&ctx, expected_output_size)
	}
	return deflate.decompress_zlib_from_context(&ctx, expected_output_size)
}

@(deprecated="Use `deflate.decompress_raw` from `core:compress/deflate`")
inflate_from_byte_array_raw :: proc(data: []u8, output: ^bytes.Buffer, expected_output_size := -1) -> (err: Error) {
	data := data
	ctx  := compress.init_context_from_slice(&data, output=&output.buf)
	return deflate.decompress_raw_from_context(&ctx, expected_output_size)
}

inflate :: proc{inflate_from_context, inflate_from_byte_array}
