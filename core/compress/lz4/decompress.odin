package compress_lz4

import "core:compress"
import "core:hash/xxhash"

decompress_block :: proc{decompress_block_to_slice, decompress_block_from_bytes, decompress_block_from_context}
decompress_frame :: proc{decompress_frame_from_bytes, decompress_frame_from_context}

decompress_block_to_slice :: proc(output, input: []u8, dictionary: []u8 = nil) -> (written: int, err: Error) {
	return lz4_decode(output, 0, 0, input, dictionary)
}

decompress_block_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, max_output_size: int, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if output == nil || max_output_size < 0 {
		return General_Error.Incompatible_Options
	}
	if max_output_size > compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		return General_Error.Output_Too_Short
	}
	non_zero_resize(output, max_output_size) or_return
	written: int
	written, err = lz4_decode(output[:], 0, 0, input, dictionary)
	non_zero_resize(output, written)
	return
}

decompress_block_from_context :: proc(z: ^compress.Context, max_output_size: int, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}

	input: []u8
	remaining: [dynamic]u8
	defer delete(remaining)
	if compress.is_memory_context(z) {
		input    = z.window
		z.window = z.window[len(z.window):]
	} else {
		remaining = compress.read_remaining(z) or_return
		input     = remaining[:]
	}

	err = decompress_block_from_bytes(z.output, input, max_output_size, dictionary, allocator)
	z.bytes_written = i64(len(z.output))
	return
}

decompress_frame_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_frame_from_context(&ctx, expected_output_size, dictionary, allocator)
}

decompress_frame_from_context :: proc(z: ^compress.Context, expected_output_size := -1, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}

	expected := expected_output_size
	if expected <= 0 && z.size_unpacked > 0 && z.size_unpacked <= i64(compress.COMPRESS_OUTPUT_ALLOCATE_MAX) {
		expected = int(z.size_unpacked)
	}
	if expected > 0 && expected <= compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		reserve(z.output, expected) or_return
	}

	scratch: [dynamic]u8
	defer delete(scratch)

	written := 0
	defer {
		non_zero_resize(z.output, written)
		z.bytes_written = i64(written)
	}

	frames := 0
	for {
		if frames > 0 {
			next, next_err := compress.peek_data(z, u32le)
			if next_err != nil || !lz4_is_magic(u32(next)) {
				return nil
			}
		}
		magic, magic_err := compress.read_data(z, u32le)
		if magic_err != nil {
			return General_Error.Stream_Too_Short
		}
		switch {
		case u32(magic) == FRAME_MAGIC:
			written = lz4_decode_frame(z, written, dictionary, &scratch) or_return
		case u32(magic) >= SKIPPABLE_MAGIC_MIN && u32(magic) <= SKIPPABLE_MAGIC_MAX:
			size, size_err := compress.read_data(z, u32le)
			if size_err != nil {
				return General_Error.Stream_Too_Short
			}
			if compress.skip(z, i64(size)) != nil {
				return General_Error.Stream_Too_Short
			}
		case u32(magic) == LEGACY_MAGIC:
			written = lz4_decode_legacy(z, written, &scratch) or_return
		case:
			return LZ4_Error.Invalid_Magic
		}
		frames += 1
	}
}

@(private)
lz4_at_end :: proc(z: ^compress.Context) -> bool {
	if compress.is_memory_context(z) {
		return len(z.window) == 0
	}
	_, err := compress.peek_data(z, u8)
	return err != nil
}

@(private)
lz4_is_magic :: proc "contextless" (magic: u32) -> bool {
	return magic == FRAME_MAGIC || magic == LEGACY_MAGIC || (magic >= SKIPPABLE_MAGIC_MIN && magic <= SKIPPABLE_MAGIC_MAX)
}

@(private)
lz4_read_bytes :: proc(z: ^compress.Context, n: int, scratch: ^[dynamic]u8) -> (data: []u8, err: Error) {
	if compress.is_memory_context(z) {
		if len(z.window) < n {
			return nil, General_Error.Stream_Too_Short
		}
		data     = z.window[:n]
		z.window = z.window[n:]
		return data, nil
	}
	non_zero_resize(scratch, n) or_return
	if compress.read_slice(z, scratch[:n]) != nil {
		return nil, General_Error.Stream_Too_Short
	}
	return scratch[:n], nil
}

@(private)
lz4_grow :: proc(output: ^[dynamic]u8, need: int) -> (err: Error) {
	if need > compress.COMPRESS_OUTPUT_ALLOCATE_MAX {
		return General_Error.Output_Too_Short
	}
	if need > len(output) {
		capacity := max(need, 2 * len(output))
		capacity  = min(capacity, compress.COMPRESS_OUTPUT_ALLOCATE_MAX)
		reserve(output, capacity) or_return
		non_zero_resize(output, need) or_return
	}
	return nil
}

@(private)
lz4_decode_frame :: proc(z: ^compress.Context, start: int, dictionary: []u8, scratch: ^[dynamic]u8) -> (written: int, err: Error) {
	descriptor: [FRAME_DESCRIPTOR_MAX]u8
	flags, flags_err := compress.read_data(z, [2]u8)
	if flags_err != nil {
		return start, General_Error.Stream_Too_Short
	}
	copy(descriptor[:], flags[:])
	descriptor_len := 2

	descriptor_flags := transmute(LZ4_Descriptor_Flags)descriptor[0]
	if descriptor_flags & {.Version_Low, .Version_High} != {.Version_Low} {
		return start, LZ4_Error.Unsupported_Version
	}
	if .Reserved in descriptor_flags || descriptor[1] & 0x8F != 0 {
		return start, LZ4_Error.Reserved_Bit_Set
	}
	code := descriptor[1] >> 4
	if code < 4 {
		return start, LZ4_Error.Invalid_Block_Max_Size
	}
	block_max          := 1 << (8 + 2 * uint(code))
	independent        := .Independent_Blocks in descriptor_flags
	block_checksum     := .Block_Checksum     in descriptor_flags
	has_content_size   := .Content_Size       in descriptor_flags
	content_checksum   := .Content_Checksum   in descriptor_flags
	has_dictionary_id  := .Dictionary_ID      in descriptor_flags

	content_size := u64(0)
	if has_content_size {
		v, e := compress.read_data(z, [8]u8)
		if e != nil {
			return start, General_Error.Stream_Too_Short
		}
		copy(descriptor[descriptor_len:], v[:])
		descriptor_len += 8
		content_size = u64(transmute(u64le)v)
	}
	if has_dictionary_id {
		v, e := compress.read_data(z, [4]u8)
		if e != nil {
			return start, General_Error.Stream_Too_Short
		}
		copy(descriptor[descriptor_len:], v[:])
		descriptor_len += 4
		if dictionary == nil {
			return start, LZ4_Error.Dictionary_Required
		}
	}
	header_checksum, hc_err := compress.read_data(z, u8)
	if hc_err != nil {
		return start, General_Error.Stream_Too_Short
	}
	if u8(xxhash.XXH32(descriptor[:descriptor_len]) >> 8) != header_checksum {
		return start, LZ4_Error.Header_Checksum_Failed
	}

	if has_content_size && content_size > u64(compress.COMPRESS_OUTPUT_ALLOCATE_MAX - start) {
		return start, General_Error.Output_Too_Short
	}
	if has_content_size {
		reserve(z.output, start + int(content_size)) or_return
	}

	written = start
	for {
		header, header_err := compress.read_data(z, u32le)
		if header_err != nil {
			return written, General_Error.Stream_Too_Short
		}
		if header == 0 {
			break
		}
		stored := u32(header) & 0x8000_0000 != 0
		size   := int(u32(header) & 0x7FFF_FFFF)
		if size > block_max {
			return written, LZ4_Error.Block_Too_Large
		}
		data := lz4_read_bytes(z, size, scratch) or_return
		if block_checksum {
			expected, e := compress.read_data(z, u32le)
			if e != nil {
				return written, General_Error.Stream_Too_Short
			}
			if xxhash.XXH32(data) != u32(expected) {
				return written, LZ4_Error.Block_Checksum_Failed
			}
		}
		if stored {
			lz4_grow(z.output, written + size) or_return
			copy(z.output[written:], data)
			written += size
			continue
		}
		lz4_grow(z.output, written + block_max) or_return
		history := start if !independent else written
		end, decode_err := lz4_decode(z.output[:written + block_max], written, history, data, dictionary)
		if decode_err != nil {
			if decode_err == General_Error.Output_Too_Short {
				return written, LZ4_Error.Block_Too_Large
			}
			return written, decode_err
		}
		written = end
	}

	if content_checksum {
		expected, e := compress.read_data(z, u32le)
		if e != nil {
			return written, General_Error.Stream_Too_Short
		}
		if xxhash.XXH32(z.output[start:written]) != u32(expected) {
			return written, LZ4_Error.Content_Checksum_Failed
		}
	}
	if has_content_size && u64(written - start) != content_size {
		return written, LZ4_Error.Content_Size_Mismatch
	}
	return written, nil
}

@(private)
lz4_decode_legacy :: proc(z: ^compress.Context, start: int, scratch: ^[dynamic]u8) -> (written: int, err: Error) {
	written = start
	for {
		if lz4_at_end(z) {
			return written, nil
		}
		size_le, size_err := compress.peek_data(z, u32le)
		if size_err != nil {
			return written, General_Error.Stream_Too_Short
		}
		size := u32(size_le)
		if lz4_is_magic(size) {
			return written, nil
		}
		_ = compress.read_data(z, u32le) or_return
		if int(size) > LEGACY_BLOCK_SIZE + LEGACY_BLOCK_SIZE / 255 + 16 {
			return written, LZ4_Error.Block_Too_Large
		}
		data := lz4_read_bytes(z, int(size), scratch) or_return
		lz4_grow(z.output, written + LEGACY_BLOCK_SIZE) or_return
		end, decode_err := lz4_decode(z.output[:written + LEGACY_BLOCK_SIZE], written, written, data, nil)
		if decode_err != nil {
			if decode_err == General_Error.Output_Too_Short {
				return written, LZ4_Error.Block_Too_Large
			}
			return written, decode_err
		}
		written = end
	}
}

@(private)
lz4_decode :: proc(output: []u8, op_start, history_start: int, input: []u8, dictionary: []u8) -> (op_end: int, err: Error) #no_bounds_check {
	src      := raw_data(input)
	dst      := raw_data(output)
	in_len   := len(input)
	out_len  := len(output)
	dict_len := len(dictionary)
	ip       := 0
	op       := op_start

	for {
		if ip >= in_len {
			return op, General_Error.Stream_Too_Short
		}
		token    := int(src[ip])
		ip       += 1
		literals := token >> 4
		offset: int

		if literals < 15 && in_len - ip >= 32 && out_len - op >= 64 {
			lz4_copy_16(dst[op:], src[ip:])
			op += literals
			ip += literals
			offset = int(lz4_load_u16(src[ip:]))
			ip += 2
			if token & 15 < 15 && offset >= 8 && offset <= op - history_start {
				m := op - offset
				lz4_copy_8(dst[op:], dst[m:])
				lz4_copy_8(dst[op + 8:], dst[m + 8:])
				if token & 15 > 12 {
					lz4_copy_8(dst[op + 16:], dst[m + 16:])
				}
				op += token & 15 + LZ4_MIN_MATCH
				continue
			}
		} else {
			if literals < 15 && in_len - ip >= 16 && out_len - op >= 16 {
				lz4_copy_16(dst[op:], src[ip:])
			} else {
				if literals == 15 {
					for {
						if ip >= in_len {
							return op, General_Error.Stream_Too_Short
						}
						b := int(src[ip])
						ip += 1
						literals += b
						if b != 255 {
							break
						}
						if literals > in_len {
							return op, LZ4_Error.Literal_Overrun
						}
					}
				}
				if literals > in_len - ip {
					return op, LZ4_Error.Literal_Overrun
				}
				if literals > out_len - op {
					return op, General_Error.Output_Too_Short
				}
				if in_len - ip - literals >= 32 && out_len - op - literals >= 32 {
					for i := 0; i < literals; i += 32 {
						lz4_copy_16(dst[op + i:], src[ip + i:])
						lz4_copy_16(dst[op + i + 16:], src[ip + i + 16:])
					}
				} else {
					copy(output[op:op + literals], input[ip:ip + literals])
				}
			}
			op += literals
			ip += literals

			if ip == in_len {
				return op, nil
			}
			if in_len - ip < 2 {
				return op, General_Error.Stream_Too_Short
			}
			offset = int(lz4_load_u16(src[ip:]))
			ip += 2
		}

		length := token & 15
		if length == 15 {
			for {
				if ip >= in_len {
					return op, General_Error.Stream_Too_Short
				}
				b := int(src[ip])
				ip += 1
				length += b
				if b != 255 {
					break
				}
				if length > out_len {
					return op, General_Error.Output_Too_Short
				}
			}
		}
		length += LZ4_MIN_MATCH

		if offset == 0 {
			return op, LZ4_Error.Invalid_Offset
		}
		if length > out_len - op {
			return op, General_Error.Output_Too_Short
		}

		history := op - history_start
		if offset > history {
			if offset > history + dict_len {
				return op, LZ4_Error.Offset_Out_Of_Range
			}
			from_dict := min(offset - history, length)
			d := dict_len - (offset - history)
			copy(output[op:op + from_dict], dictionary[d:d + from_dict])
			for i in from_dict..<length {
				dst[op + i] = dst[history_start + i - from_dict]
			}
			op += length
			continue
		}

		m := op - offset
		switch {
		case offset >= 32 && out_len - op - length >= 32:
			for i := 0; i < length; i += 32 {
				lz4_copy_16(dst[op + i:], dst[m + i:])
				lz4_copy_16(dst[op + i + 16:], dst[m + i + 16:])
			}
		case offset >= 16 && out_len - op - length >= 16:
			for i := 0; i < length; i += 16 {
				lz4_copy_16(dst[op + i:], dst[m + i:])
			}
		case offset >= 8 && out_len - op - length >= 8:
			for i := 0; i < length; i += 8 {
				lz4_copy_8(dst[op + i:], dst[m + i:])
			}
		case out_len - op - length >= 8:
			for i in 0..<8 {
				dst[op + i] = dst[m + i]
			}
			period := LZ4_SHORT_OFFSET_PERIOD[offset]
			for i := 8; i < length; i += 8 {
				lz4_copy_8(dst[op + i:], dst[op + i - period:])
			}
		case:
			for i in 0..<length {
				dst[op + i] = dst[m + i]
			}
		}
		op += length
	}
}

@(private, rodata)
LZ4_SHORT_OFFSET_PERIOD := [8]int{0, 8, 8, 9, 8, 10, 12, 14}
