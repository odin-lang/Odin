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

@(deprecated="Use `deflate.inflate_zlib` or `deflate.inflate_raw` from `core:compress/deflate`")
inflate_from_context :: proc(ctx: ^compress.Context, raw := false, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	if raw {
		return deflate.inflate_raw_from_context(ctx, expected_output_size, allocator=allocator)
	}
	return deflate.inflate_zlib_from_context(ctx, expected_output_size, allocator=allocator)
}

@(deprecated="Use `deflate.inflate_raw` from `core:compress/deflate`")
inflate_raw :: proc(z: ^compress.Context, expected_output_size := -1, allocator := context.allocator) -> (err: Error) {
	return deflate.inflate_raw_from_context(z, expected_output_size, allocator=allocator)
}

@(deprecated="Use `deflate.inflate_zlib` or `deflate.inflate_raw` from `core:compress/deflate`")
inflate_from_byte_array :: proc(data: []u8, output: ^bytes.Buffer, raw := false, size_unpacked := -1) -> (err: Error) {
	data := data
	ctx  := compress.init_context_from_slice(&data, output=&output.buf, size_unpacked=i64(size_unpacked))
	if raw {
		return deflate.inflate_raw_from_context(&ctx)
	}
	return deflate.inflate_zlib_from_context(&ctx)
}

@(deprecated="Use `deflate.inflate_raw` from `core:compress/deflate`")
inflate_from_byte_array_raw :: proc(data: []u8, output: ^bytes.Buffer, size_unpacked := -1) -> (err: Error) {
	data := data
	ctx  := compress.init_context_from_slice(&data, output=&output.buf, size_unpacked=i64(size_unpacked))
	return deflate.inflate_raw_from_context(&ctx)
}

inflate :: proc{inflate_from_context, inflate_from_byte_array}
