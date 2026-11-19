package compress_deflate

import "core:compress"
import "core:hash"
import "core:io"

decompress_gzip :: proc{decompress_gzip_from_context, decompress_gzip_from_bytes}

decompress_gzip_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	expected := compress.declared_size(expected_output_size)
	if expected > compress.output_limit(options) {
		return General_Error.Output_Too_Short
	}

	isize := i64(-1)
	if compress.is_memory_context(z) && len(z.window) >= size_of(Gzip_Trailer) {
		isize = min(i64((^u32le)(raw_data(z.window[len(z.window) - 4:]))^), INFLATE_INITIAL_SIZE_MAX)
	}
	size_hint := compress.declared_size(expected, isize)

	p: Inflate_Progress
	inflate_progress_init(&p, z, expected, options) or_return

	start := 0
	for {
		_, header_size := inflate_gzip_header(z) or_return
		p.bytes_in += i64(header_size)
		digest := u32(0)
		output := inflate_to_buffer(z, expected, &p, start, size_hint, .CRC32, &digest, false) or_return
		member := output[start:]

		trailer, trailer_err := compress.read_data(z, Gzip_Trailer)
		if trailer_err != nil {
			return General_Error.Stream_Too_Short
		}
		p.bytes_in += size_of(Gzip_Trailer)
		if u32le(digest) != trailer.crc32 {
			return GZIP_Error.Payload_CRC_Invalid
		}
		if u32le(u32(len(member))) != trailer.size {
			return GZIP_Error.Payload_Length_Invalid
		}
		inflate_progress_step(&p, p.bytes_in, i64(len(output))) or_return

		start = len(output)
		magic, magic_err := compress.peek_data(z, Gzip_Magic)
		if magic_err != nil || magic != .GZIP {
			if expected >= 0 && start != expected {
				return General_Error.Size_Mismatch
			}
			return nil
		}
	}
}

decompress_gzip_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_gzip_from_context(&ctx, expected_output_size, options, allocator)
}

decompress_gzip_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, allocator := context.allocator) -> (err: Error) {
	return inflate_stream_to_writer(w, z, .Gzip, expected_output_size, options, allocator)
}

@(private)
inflate_gzip_skip_string :: proc(z: ^compress.Context, crc: ^u32, too_long: GZIP_Error) -> (size: int, err: Error) {
	for i := 0; ; i += 1 {
		if i >= GZIP_STRING_MAX {
			return i, too_long
		}
		b, read_err := compress.read_u8(z)
		if read_err != nil {
			return i, General_Error.Stream_Too_Short
		}
		if crc != nil {
			crc^ = hash.crc32(([^]u8)(&b)[:1], crc^)
		}
		if b == 0 {
			return i + 1, nil
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
inflate_gzip_header :: proc(z: ^compress.Context) -> (header: Gzip_Header, size: int, err: Error) {
	read_err: io.Error
	header, read_err = compress.read_data(z, Gzip_Header)
	if read_err != nil {
		return header, 0, General_Error.File_Too_Short
	}
	size = size_of(Gzip_Header)
	crc: u32
	crc_ptr: ^u32
	if .header_crc in header.flags {
		crc     = hash.crc32(([^]u8)(&header)[:size_of(Gzip_Header)])
		crc_ptr = &crc
	}
	if header.magic != .GZIP {
		return header, size, GZIP_Error.Invalid_GZIP_Signature
	}
	if header.compression_method != .DEFLATE {
		return header, size, General_Error.Unknown_Compression_Method
	}
	if header.os >= ._Unknown {
		header.os = .Unknown
	}
	if header.flags & {.reserved_1, .reserved_2, .reserved_3} != {} {
		return header, size, GZIP_Error.Reserved_Flag_Set
	}

	if .extra in header.flags {
		xlen, xlen_err := compress.read_data(z, u16le)
		if xlen_err != nil {
			return header, size, General_Error.Stream_Too_Short
		}
		size += size_of(xlen) + int(xlen)
		if crc_ptr != nil {
			crc = hash.crc32(([^]u8)(&xlen)[:size_of(xlen)], crc)
		}
		for xlen > 0 {
			if xlen < 4 {
				return header, size, GZIP_Error.Invalid_Extra_Data
			}
			field, field_err := compress.read_data(z, [2]u16le)
			if field_err != nil {
				return header, size, General_Error.Stream_Too_Short
			}
			if crc_ptr != nil {
				crc = hash.crc32(([^]u8)(&field)[:size_of(field)], crc)
			}
			xlen -= 4
			if field[1] > xlen {
				return header, size, GZIP_Error.Invalid_Extra_Data
			}
			inflate_gzip_skip_bytes(z, crc_ptr, int(field[1])) or_return
			xlen -= field[1]
		}
	}

	if .name in header.flags {
		size += inflate_gzip_skip_string(z, crc_ptr, .Original_Name_Too_Long) or_return
	}
	if .comment in header.flags {
		size += inflate_gzip_skip_string(z, crc_ptr, .Comment_Too_Long) or_return
	}
	if .header_crc in header.flags {
		header_crc, header_crc_err := compress.read_data(z, u16le)
		if header_crc_err != nil {
			return header, size, General_Error.Stream_Too_Short
		}
		size += size_of(header_crc)
		if u16(header_crc) != u16(crc) {
			return header, size, GZIP_Error.Header_CRC_Invalid
		}
	}
	return header, size, nil
}
