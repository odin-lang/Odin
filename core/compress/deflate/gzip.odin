package compress_deflate

import "core:compress"
import "core:hash"
import "core:io"

inflate_gzip :: proc{inflate_gzip_from_context, inflate_gzip_from_bytes}

inflate_gzip_from_context :: proc(z: ^compress.Context, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	expected_output_size := expected_output_size
	if expected_output_size <= 0 && z.size_unpacked > 0 {
		expected_output_size = int(min(z.size_unpacked, i64(max(int))))
	}
	if expected_output_size > max_output_size {
		return General_Error.Output_Exceeds_COMPRESS_OUTPUT_ALLOCATE_MAX
	}

	size_hint := -1
	if expected_output_size <= 0 && compress.is_memory_context(z) && len(z.window) >= size_of(Gzip_Trailer) {
		size_hint = int((^u32le)(raw_data(z.window[len(z.window) - 4:]))^)
	}

	start := 0
	for {
		inflate_gzip_header(z) or_return
		output := inflate_to_buffer(z, expected_output_size, max_output_size, start, size_hint) or_return
		member := output[start:]

		trailer, trailer_err := compress.read_data(z, Gzip_Trailer)
		if trailer_err != nil {
			return General_Error.Stream_Too_Short
		}
		if u32le(hash.crc32(member)) != trailer.crc32 {
			return GZIP_Error.Payload_CRC_Invalid
		}
		if u32le(u32(len(member))) != trailer.size {
			return GZIP_Error.Payload_Length_Invalid
		}

		start = len(output)
		magic, magic_err := compress.peek_data(z, Gzip_Magic)
		if magic_err != nil || magic != .GZIP {
			return nil
		}
	}
}

inflate_gzip_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return inflate_gzip_from_context(&ctx, expected_output_size, max_output_size, allocator)
}

@(private)
inflate_gzip_skip_string :: proc(z: ^compress.Context, crc: ^u32, too_long: GZIP_Error) -> (err: Error) {
	for i := 0; ; i += 1 {
		if i >= GZIP_STRING_MAX {
			return too_long
		}
		b, read_err := compress.read_u8(z)
		if read_err != nil {
			return General_Error.Stream_Too_Short
		}
		if crc != nil {
			crc^ = hash.crc32(([^]u8)(&b)[:1], crc^)
		}
		if b == 0 {
			return nil
		}
	}
}

@(private)
inflate_gzip_skip_bytes :: proc(z: ^compress.Context, crc: ^u32, count: int) -> (err: Error) {
	if crc == nil {
		if compress.skip(z, i64(count)) != nil {
			return General_Error.Stream_Too_Short
		}
		return nil
	}
	buffer: [256]u8
	remaining := count
	for remaining > 0 {
		chunk := buffer[:min(remaining, len(buffer))]
		if compress.read_slice(z, chunk) != nil {
			return General_Error.Stream_Too_Short
		}
		crc^ = hash.crc32(chunk, crc^)
		remaining -= len(chunk)
	}
	return nil
}

@(private)
inflate_gzip_header :: proc(z: ^compress.Context) -> (header: Gzip_Header, err: Error) {
	read_err: io.Error
	header, read_err = compress.read_data(z, Gzip_Header)
	if read_err != nil {
		return header, General_Error.File_Too_Short
	}
	crc: u32
	crc_ptr: ^u32
	if .header_crc in header.flags {
		crc     = hash.crc32(([^]u8)(&header)[:size_of(Gzip_Header)])
		crc_ptr = &crc
	}
	if header.magic != .GZIP {
		return header, GZIP_Error.Invalid_GZIP_Signature
	}
	if header.compression_method != .DEFLATE {
		return header, General_Error.Unknown_Compression_Method
	}
	if header.os >= ._Unknown {
		header.os = .Unknown
	}
	if header.flags & {.reserved_1, .reserved_2, .reserved_3} != {} {
		return header, GZIP_Error.Reserved_Flag_Set
	}

	if .extra in header.flags {
		xlen, xlen_err := compress.read_data(z, u16le)
		if xlen_err != nil {
			return header, General_Error.Stream_Too_Short
		}
		if crc_ptr != nil {
			crc = hash.crc32(([^]u8)(&xlen)[:size_of(xlen)], crc)
		}
		for xlen > 0 {
			if xlen < 4 {
				return header, GZIP_Error.Invalid_Extra_Data
			}
			field, field_err := compress.read_data(z, [2]u16le)
			if field_err != nil {
				return header, General_Error.Stream_Too_Short
			}
			if crc_ptr != nil {
				crc = hash.crc32(([^]u8)(&field)[:size_of(field)], crc)
			}
			xlen -= 4
			if field[1] > xlen {
				return header, GZIP_Error.Invalid_Extra_Data
			}
			inflate_gzip_skip_bytes(z, crc_ptr, int(field[1])) or_return
			xlen -= field[1]
		}
	}

	if .name in header.flags {
		inflate_gzip_skip_string(z, crc_ptr, .Original_Name_Too_Long) or_return
	}
	if .comment in header.flags {
		inflate_gzip_skip_string(z, crc_ptr, .Comment_Too_Long) or_return
	}
	if .header_crc in header.flags {
		header_crc, header_crc_err := compress.read_data(z, u16le)
		if header_crc_err != nil {
			return header, General_Error.Stream_Too_Short
		}
		if u16(header_crc) != u16(crc) {
			return header, GZIP_Error.Header_CRC_Invalid
		}
	}
	return header, nil
}
