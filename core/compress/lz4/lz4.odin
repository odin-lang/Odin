package lz4

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation, optimization.

	Thanks to Yann Collet for creating the LZ4 compression format.
	This implementation is written in accordance with the 
		(LZ4 block and frame specifications)[https://github.com/lz4/lz4/tree/dev/doc]
*/

import "core:compress"

// import "core:mem"
// import "core:hash"
import "core:bytes"
import "core:fmt"

Error :: compress.Error

@(optimization_mode="speed")
uncompress_from_context :: proc(using ctx: ^compress.Context_Memory_Input, expected_output_size := -1, allocator := context.allocator) -> (err: Error) #no_bounds_check {
	/*
		ctx.output must be a bytes.Buffer for now. We'll add a separate implementation that writes to a stream.
	*/
	expected_output_size := expected_output_size

	/*
		Always set up a minimum allocation size.
	*/
	expected_output_size = max(max(expected_output_size, compress.COMPRESS_OUTPUT_ALLOCATE_MIN), 512)

	if expected_output_size > 0 && expected_output_size <= compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		/*
			Try to pre-allocate the output buffer.
		*/
		reserve(&ctx.output.buf, expected_output_size)
		resize (&ctx.output.buf, expected_output_size)
	}

	if len(ctx.output.buf) != expected_output_size {
		return .Resize_Failed
	}

	ctx.num_bits    = 0
	ctx.code_buffer = 0


	parse_header(ctx) or_return

	return nil
}

uncompress_from_byte_array :: proc(input: []u8, buf: ^bytes.Buffer, expected_output_size := -1) -> (err: Error) {
	ctx := compress.Context_Memory_Input{}

	ctx.input_data = input
	ctx.output = buf

	return uncompress_from_context(ctx=&ctx, expected_output_size=expected_output_size)
}

uncompress :: proc{uncompress_from_context, uncompress_from_byte_array}


parse_header :: proc(z: ^$C) -> (err: Error) {
	magic := compress.read_data(z, Magic) or_return

	fmt.printf("magic: %v\n", magic)

	return nil
}