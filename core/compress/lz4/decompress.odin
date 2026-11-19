package compress_lz4

import "base:runtime"
import "core:compress"
import "core:hash/xxhash"
import "core:io"

decompress_block :: proc{decompress_block_to_slice, decompress_block_from_bytes, decompress_block_from_context}
decompress_frame :: proc{decompress_frame_from_bytes, decompress_frame_from_context}

decompress_block_to_slice :: proc(output, input: []u8, options: compress.Options = {}, dictionary: []u8 = nil) -> (written: int, err: Error) {
	lz4_check_options(options) or_return
	return lz4_decode_block(output[:lz4_output_size(len(output), options)], input, options, dictionary, -1)
}

decompress_block_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	expected := lz4_block_check(output, expected_output_size, options) or_return

	size := min(compress.output_limit(options), lz4_decompress_bound(len(input)))
	if expected >= 0 {
		size = min(expected, lz4_decompress_bound(len(input)))
	}
	non_zero_resize(output, size) or_return
	written: int
	written, err = lz4_decode_block(output[:], input, options, dictionary, i64(expected))
	non_zero_resize(output, written)
	if expected >= 0 && (err == General_Error.Output_Too_Short || (err == nil && written != expected)) {
		return General_Error.Size_Mismatch
	}
	return
}

decompress_block_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	lz4_block_check(z.output, expected_output_size, options) or_return

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

	err = decompress_block_from_bytes(z.output, input, expected_output_size, options, dictionary, allocator)
	z.bytes_written = i64(len(z.output))
	return
}

decompress_frame_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return decompress_frame_from_context(&ctx, expected_output_size, options, dictionary, allocator)
}

decompress_frame_from_context :: proc(z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	if z.output == nil {
		return General_Error.Incompatible_Options
	}
	lz4_check_options(options) or_return

	expected := compress.declared_size(expected_output_size)
	limit    := compress.output_limit(options)
	if expected >= 0 {
		if expected > limit {
			return General_Error.Output_Too_Short
		}
		limit = expected
	}

	input_size := compress.input_size(z)
	if expected >= 0 {
		non_zero_reserve(z.output, lz4_initial_size(expected, input_size)) or_return
	}

	scratch: [dynamic]u8
	defer delete(scratch)

	written := 0
	defer {
		non_zero_resize(z.output, written)
		z.bytes_written = i64(written)
	}

	progress := lz4_progress_init(options, 0, i64(input_size), i64(expected))
	frames   := 0
	frame_loop: for {
		if frames > 0 {
			next, next_err := compress.peek_data(z, u32le)
			if next_err != nil || !lz4_is_magic(u32(next)) {
				break frame_loop
			}
		}
		magic, magic_err := compress.read_data(z, u32le)
		if magic_err != nil {
			return General_Error.Stream_Too_Short
		}
		progress.consumed += 4
		switch {
		case u32(magic) == FRAME_MAGIC:
			written, err = lz4_decode_frame(z, written, limit, input_size, dictionary, &scratch, &progress)
			if err != nil {
				break frame_loop
			}
		case u32(magic) >= SKIPPABLE_MAGIC_MIN && u32(magic) <= SKIPPABLE_MAGIC_MAX:
			size, size_err := compress.read_data(z, u32le)
			if size_err != nil {
				return General_Error.Stream_Too_Short
			}
			if compress.skip(z, i64(size)) != nil {
				return General_Error.Stream_Too_Short
			}
			progress.consumed += 4 + i64(size)
		case u32(magic) == LEGACY_MAGIC:
			written, err = lz4_decode_legacy(z, written, limit, &scratch, &progress)
			if err != nil {
				break frame_loop
			}
		case:
			return LZ4_Error.Invalid_Magic
		}
		frames += 1
	}
	if expected >= 0 && (err == General_Error.Output_Too_Short || (err == nil && written != expected)) {
		return General_Error.Size_Mismatch
	}
	return
}

decompress_frame_to_writer :: proc(w: io.Writer, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	r: Frame_Reader
	defer frame_reader_destroy(&r)
	lz4_stream_init(&r, z, expected_output_size, options, dictionary, allocator) or_return
	for !r.done {
		fill_err := lz4_stream_fill(&r)
		produced := r.written > r.flushed
		if produced {
			_, write_err := io.write_full(w, r.window[r.flushed:r.written])
			if write_err != nil {
				return write_err
			}
			r.flushed = r.written
		}
		if fill_err != nil {
			return fill_err
		}
		if produced || r.done {
			lz4_reader_progress(&r) or_return
		}
	}
	return nil
}

frame_reader_init :: proc(r: ^Frame_Reader, z: ^compress.Context, expected_output_size := -1, options: compress.Options = {}, dictionary: []u8 = nil, allocator := context.allocator) -> (err: Error) {
	err   = lz4_stream_init(r, z, expected_output_size, options, dictionary, allocator)
	r.err = err
	return
}

frame_reader_read :: proc(r: ^Frame_Reader, p: []u8) -> (n: int, err: Error) {
	was_done := r.done
	for n < len(p) {
		if r.flushed < r.written {
			copied   := copy(p[n:], r.window[r.flushed:r.written])
			r.flushed += copied
			n         += copied
		} else if r.done || r.err != nil {
			break
		} else {
			r.err = lz4_stream_fill(r)
		}
	}
	if (n > 0 || (r.done && !was_done)) && r.err == nil {
		if r.err = lz4_reader_progress(r); r.err != nil {
			r.flushed = r.written
		}
	}
	if n > 0 || r.flushed < r.written {
		return n, nil
	}
	if r.err != nil {
		return 0, r.err
	}
	if len(p) > 0 && r.done {
		return 0, io.Error.EOF
	}
	return 0, nil
}

frame_reader_to_stream :: proc(r: ^Frame_Reader) -> (s: io.Stream) {
	s.data      = r
	s.procedure = lz4_reader_stream_proc
	return
}

frame_reader_destroy :: proc(r: ^Frame_Reader) {
	if r.owns_window {
		delete(r.window, r.allocator)
	}
	delete(r.scratch)
	r.scratch     = nil
	r.window      = nil
	r.written     = 0
	r.flushed     = 0
	r.owns_window = false
}

@(private)
lz4_block_check :: proc "contextless" (output: ^[dynamic]u8, expected_output_size: int, options: compress.Options) -> (expected: int, err: Error) {
	if output == nil {
		return -1, General_Error.Incompatible_Options
	}
	lz4_check_options(options) or_return
	expected = compress.declared_size(expected_output_size)
	if expected > compress.output_limit(options) {
		return expected, General_Error.Output_Too_Short
	}
	return
}

@(private)
lz4_decode_block :: proc(output, input: []u8, options: compress.Options, dictionary: []u8, total_out: i64) -> (written: int, err: Error) {
	if options.progress == nil {
		return lz4_decode(output, 0, 0, input, dictionary, false, nil)
	}
	progress := lz4_progress_init(options, 0, i64(len(input)), total_out)
	return lz4_decode(output, 0, 0, input, dictionary, true, &progress)
}

@(private)
lz4_reader_progress :: proc(r: ^Frame_Reader) -> (err: Error) {
	return compress.report_progress(r.options, r.consumed, r.total - i64(r.written - r.flushed), r.total_in, r.total_out)
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
lz4_decompress_bound :: proc "contextless" (input_size: int) -> int {
	if input_size > max(int) / compress.LZ4_EXPANSION_MAX {
		return max(int)
	}
	return compress.LZ4_EXPANSION_MAX * input_size
}

@(private)
lz4_initial_size :: proc "contextless" (size, input_size: int) -> int {
	return compress.output_reservation(size, lz4_decompress_bound(input_size) if input_size >= 0 else -1, input_size)
}

@(private)
lz4_grow :: proc(output: ^[dynamic]u8, need, limit: int) -> (err: Error) {
	if need > limit {
		return General_Error.Output_Too_Short
	}
	if need > len(output) {
		if need > cap(output) {
			non_zero_reserve(output, compress.output_grow_capacity(cap(output), need, limit)) or_return
		}
		non_zero_resize(output, need) or_return
	}
	return nil
}

@(private)
lz4_frame_header :: proc(z: ^compress.Context, dictionary: []u8) -> (h: LZ4_Frame_Header, err: Error) {
	descriptor: [FRAME_DESCRIPTOR_MAX]u8
	flags, flags_err := compress.read_data(z, [2]u8)
	if flags_err != nil {
		return h, General_Error.Stream_Too_Short
	}
	copy(descriptor[:], flags[:])
	descriptor_len := 2

	descriptor_flags := transmute(LZ4_Descriptor_Flags)descriptor[0]
	if descriptor_flags & {.Version_Low, .Version_High} != {.Version_Low} {
		return h, LZ4_Error.Unsupported_Version
	}
	if .Reserved in descriptor_flags || descriptor[1] & 0x8F != 0 {
		return h, LZ4_Error.Reserved_Bit_Set
	}
	code := descriptor[1] >> 4
	if code < 4 {
		return h, LZ4_Error.Invalid_Block_Max_Size
	}
	h.block_max        = 1 << (8 + 2 * uint(code))
	h.independent      = .Independent_Blocks in descriptor_flags
	h.block_checksum   = .Block_Checksum     in descriptor_flags
	h.content_checksum = .Content_Checksum   in descriptor_flags
	h.content_size     = -1

	if .Content_Size in descriptor_flags {
		v, e := compress.read_data(z, [8]u8)
		if e != nil {
			return h, General_Error.Stream_Too_Short
		}
		copy(descriptor[descriptor_len:], v[:])
		descriptor_len += 8
		size := u64(transmute(u64le)v)
		h.content_size = i64(min(size, u64(max(i64))))
	}
	if .Dictionary_ID in descriptor_flags {
		v, e := compress.read_data(z, [4]u8)
		if e != nil {
			return h, General_Error.Stream_Too_Short
		}
		copy(descriptor[descriptor_len:], v[:])
		descriptor_len += 4
		if dictionary == nil {
			return h, LZ4_Error.Dictionary_Required
		}
	}
	header_checksum, hc_err := compress.read_data(z, u8)
	if hc_err != nil {
		return h, General_Error.Stream_Too_Short
	}
	if u8(xxhash.XXH32(descriptor[:descriptor_len]) >> 8) != header_checksum {
		return h, LZ4_Error.Header_Checksum_Failed
	}
	h.size = descriptor_len + 1
	return h, nil
}

@(private)
lz4_decode_frame :: proc(z: ^compress.Context, start, limit, input_size: int, dictionary: []u8, scratch: ^[dynamic]u8, progress: ^LZ4_Check) -> (written: int, err: Error) {
	h, header_err := lz4_frame_header(z, dictionary)
	if header_err != nil {
		return start, header_err
	}
	progress.consumed += i64(h.size)
	block_max        := h.block_max
	independent      := h.independent
	block_checksum   := h.block_checksum
	content_checksum := h.content_checksum
	has_content_size := h.content_size >= 0
	content_size     := u64(h.content_size) if has_content_size else 0

	frame_limit := limit
	overflow    := Error(General_Error.Output_Too_Short)
	if has_content_size {
		if content_size > u64(limit - start) {
			return start, General_Error.Output_Too_Short
		}
		frame_limit = start + int(content_size)
		overflow    = General_Error.Size_Mismatch
		if start + lz4_initial_size(int(content_size), input_size) > cap(z.output) {
			non_zero_reserve(z.output, start + lz4_initial_size(int(content_size), input_size)) or_return
		}
	} else if start == 0 {
		reservation := min(lz4_initial_size(-1, input_size), limit)
		if reservation > cap(z.output) {
			non_zero_reserve(z.output, reservation) or_return
		}
	}

	written = start
	for {
		if written >= progress.mark && lz4_progress_report(progress, written, progress.consumed, i64(written)) {
			return written, progress.err
		}
		header, header_err := compress.read_data(z, u32le)
		if header_err != nil {
			return written, General_Error.Stream_Too_Short
		}
		progress.consumed += 4
		if header == 0 {
			break
		}
		stored := u32(header) & 0x8000_0000 != 0
		size   := int(u32(header) & 0x7FFF_FFFF)
		if size > block_max {
			return written, LZ4_Error.Block_Too_Large
		}
		data := lz4_read_bytes(z, size, scratch) or_return
		progress.consumed += i64(size)
		if block_checksum {
			expected, e := compress.read_data(z, u32le)
			if e != nil {
				return written, General_Error.Stream_Too_Short
			}
			progress.consumed += 4
			if xxhash.XXH32(data) != u32(expected) {
				return written, LZ4_Error.Block_Checksum_Failed
			}
		}
		if stored {
			if size > frame_limit - written {
				return written, overflow
			}
			lz4_grow(z.output, written + size, frame_limit) or_return
			copy(z.output[written:], data)
			written += size
			continue
		}
		window := min(block_max, frame_limit - written)
		lz4_grow(z.output, written + window, frame_limit) or_return
		history := start if !independent else written
		end, decode_err := lz4_decode(z.output[:written + window], written, history, data, dictionary, false, nil)
		if decode_err != nil {
			if decode_err == General_Error.Output_Too_Short {
				return written, overflow if window < block_max else LZ4_Error.Block_Too_Large
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
		progress.consumed += 4
		if xxhash.XXH32(z.output[start:written]) != u32(expected) {
			return written, LZ4_Error.Content_Checksum_Failed
		}
	}
	if has_content_size && u64(written - start) != content_size {
		return written, General_Error.Size_Mismatch
	}
	return written, nil
}

@(private)
lz4_decode_legacy :: proc(z: ^compress.Context, start, limit: int, scratch: ^[dynamic]u8, progress: ^LZ4_Check) -> (written: int, err: Error) {
	written = start
	for {
		if written >= progress.mark && lz4_progress_report(progress, written, progress.consumed, i64(written)) {
			return written, progress.err
		}
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
		progress.consumed += 4 + i64(size)
		window := min(LEGACY_BLOCK_SIZE, limit - written)
		lz4_grow(z.output, written + window, limit) or_return
		end, decode_err := lz4_decode(z.output[:written + window], written, written, data, nil, false, nil)
		if decode_err != nil {
			if decode_err == General_Error.Output_Too_Short {
				return written, General_Error.Output_Too_Short if window < LEGACY_BLOCK_SIZE else LZ4_Error.Block_Too_Large
			}
			return written, decode_err
		}
		written = end
	}
}

@(private)
lz4_decode :: proc(output: []u8, op_start, history_start: int, input: []u8, dictionary: []u8, $PROGRESS: bool, progress: ^LZ4_Check) -> (op_end: int, err: Error) #no_bounds_check {
	src      := raw_data(input)
	dst      := raw_data(output)
	in_len   := len(input)
	out_len  := len(output)
	dict_len := len(dictionary)
	ip       := 0
	op       := op_start

	for {
		token, offset: int
		pending := false
		when ODIN_ARCH == .amd64 {
			for in_len - ip >= 33 && out_len - op >= 64 {
				when PROGRESS {
					if op >= progress.mark {
						break
					}
				}
				t := int(src[ip])
				if t >= 0xF0 {
					break
				}
				lz4_copy_16(dst[op:], src[ip + 1:])
				op += t >> 4
				ip += t >> 4 + 1
				o := int(lz4_load_u16(src[ip:]))
				ip += 2
				if t & 15 == 15 || o < 8 || o > op - history_start {
					token, offset, pending = t, o, true
					break
				}
				m := op - o
				lz4_copy_8(dst[op:], dst[m:])
				lz4_copy_8(dst[op + 8:], dst[m + 8:])
				if t & 15 > 12 {
					lz4_copy_8(dst[op + 16:], dst[m + 16:])
				}
				op += t & 15 + LZ4_MIN_MATCH
			}
		}

		if !pending {
			when PROGRESS {
				if op >= progress.mark && lz4_progress_report(progress, op, i64(ip), i64(op - op_start)) {
					return op, progress.err
				}
			}
			if ip >= in_len {
				return op, General_Error.Stream_Too_Short
			}
			token = int(src[ip])
			ip += 1
			literals := token >> 4
			if ODIN_ARCH != .amd64 && literals < 15 && in_len - ip >= 32 && out_len - op >= 64 {
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

@(private)
lz4_stream_init :: proc(r: ^Frame_Reader, z: ^compress.Context, expected_output_size: int, options: compress.Options, dictionary: []u8, allocator: runtime.Allocator) -> (err: Error) {
	r^ = {}
	r.z                 = z
	r.dictionary        = dictionary
	r.allocator         = allocator
	r.scratch.allocator = allocator
	r.buffer            = options.buffer
	r.limit             = -1
	r.frame_limit       = -1
	r.content_size      = -1
	r.chunk             = options.chunk_size if options.chunk_size > 0 else CHUNK_SIZE
	r.memory_max        = compress.memory_limit(options)
	r.options           = options
	r.total_in          = -1
	r.total_out         = -1

	if options.max_output_size < 0 {
		return General_Error.Output_Too_Short
	}
	if options.max_memory < 0 || options.chunk_size < 0 || options.progress_interval < 0 {
		return General_Error.Incompatible_Options
	}
	expected := i64(compress.declared_size(expected_output_size))
	r.total_out = expected
	if options.progress != nil {
		r.total_in = i64(compress.input_size(z))
	}
	if options.max_output_size > 0 {
		r.limit = i64(options.max_output_size)
	}
	if expected >= 0 {
		if r.limit >= 0 && expected > r.limit {
			return General_Error.Output_Too_Short
		}
		r.limit = expected
	}
	return nil
}

@(private)
lz4_stream_reserve :: proc(r: ^Frame_Reader, history, need: int, room: i64) -> (err: Error) {
	required := history + need
	if room >= 0 && i64(required) > room {
		required = int(room)
	}
	if len(r.window) >= required {
		return nil
	}
	if r.buffer != nil {
		if len(r.buffer) < required {
			return General_Error.Incompatible_Options
		}
		r.window = r.buffer
		return nil
	}

	scratch := 0 if compress.is_memory_context(r.z) else need
	if required > r.memory_max - scratch {
		return General_Error.Memory_Limit_Exceeded
	}
	size := history + max(need, r.chunk)
	if room >= 0 && i64(size) > room {
		size = int(room)
	}
	size = clamp(size, required, r.memory_max - scratch)

	window  := non_zero_make([]u8, size, r.allocator) or_return
	pending := copy(window, r.window[r.flushed:r.written])
	if r.owns_window {
		delete(r.window, r.allocator)
	}
	r.base        = max(r.base - r.flushed, 0)
	r.written     = pending
	r.flushed     = 0
	r.window      = window
	r.owns_window = true
	return nil
}

@(private)
lz4_stream_room :: proc(r: ^Frame_Reader, need: int, produced: bool) -> (ok: bool) {
	if len(r.window) - r.written >= need {
		return true
	}
	if produced || r.flushed < r.written {
		return false
	}
	keep  := min(r.written - r.base, r.history)
	shift := r.written - keep
	copy(r.window, r.window[shift:r.written])
	r.written = keep
	r.flushed = keep
	r.base    = max(r.base - shift, 0)
	return len(r.window) - r.written >= need
}

@(private)
lz4_stream_fill :: proc(r: ^Frame_Reader) -> (err: Error) {
	defer r.z.bytes_written = r.total
	produced := false
	for {
		switch r.state {
		case .Done:
			r.done = true
			if r.total_out >= 0 && r.total != r.total_out {
				return General_Error.Size_Mismatch
			}
			return nil

		case .Magic:
			if r.frames > 0 {
				next, next_err := compress.peek_data(r.z, u32le)
				if next_err != nil || !lz4_is_magic(u32(next)) {
					r.state = .Done
					continue
				}
			}
			magic, magic_err := compress.read_data(r.z, u32le)
			if magic_err != nil {
				return General_Error.Stream_Too_Short
			}
			r.consumed += 4
			switch {
			case u32(magic) == FRAME_MAGIC:
				h := lz4_frame_header(r.z, r.dictionary) or_return
				r.consumed += i64(h.size)
				room := r.limit - r.total if r.limit >= 0 else -1
				r.frame_limit  = r.limit
				r.content_size = h.content_size
				if h.content_size >= 0 {
					if room >= 0 && h.content_size > room {
						return General_Error.Size_Mismatch if r.total_out >= 0 else General_Error.Output_Too_Short
					}
					room          = h.content_size
					r.frame_limit = r.total + h.content_size
				}
				r.block_max    = h.block_max
				r.independent  = h.independent
				r.checksummed  = h.block_checksum
				r.content_hash = h.content_checksum
				r.history      = 0 if h.independent else LZ4_WINDOW_SIZE
				r.frame_start  = r.total
				need := h.block_max
				if room >= 0 && i64(need) > room {
					need = int(room)
				}
				lz4_stream_reserve(r, r.history, need, room) or_return
				r.base = r.written
				if h.content_checksum {
					xxhash.XXH32_reset_state(&r.digest)
				}
				r.state = .Frame
			case u32(magic) >= SKIPPABLE_MAGIC_MIN && u32(magic) <= SKIPPABLE_MAGIC_MAX:
				size, size_err := compress.read_data(r.z, u32le)
				if size_err != nil {
					return General_Error.Stream_Too_Short
				}
				if compress.skip(r.z, i64(size)) != nil {
					return General_Error.Stream_Too_Short
				}
				r.consumed += 4 + i64(size)
				r.frames   += 1
			case u32(magic) == LEGACY_MAGIC:
				room := r.limit - r.total if r.limit >= 0 else -1
				need := LEGACY_BLOCK_SIZE
				if room >= 0 && i64(need) > room {
					need = int(room)
				}
				r.history     = 0
				r.frame_limit = r.limit
				lz4_stream_reserve(r, 0, need, room) or_return
				r.base  = r.written
				r.state = .Legacy
			case:
				return LZ4_Error.Invalid_Magic
			}

		case .Frame:
			room := r.frame_limit - r.total if r.frame_limit >= 0 else i64(max(int))
			need := int(min(i64(r.block_max), room))
			if !lz4_stream_room(r, need, produced) {
				return nil
			}
			header, header_err := compress.read_data(r.z, u32le)
			if header_err != nil {
				return General_Error.Stream_Too_Short
			}
			r.consumed += 4
			if header == 0 {
				if r.content_hash {
					expected, e := compress.read_data(r.z, u32le)
					if e != nil {
						return General_Error.Stream_Too_Short
					}
					r.consumed += 4
					if xxhash.XXH32_digest(&r.digest) != u32(expected) {
						return LZ4_Error.Content_Checksum_Failed
					}
				}
				if r.content_size >= 0 && r.total - r.frame_start != r.content_size {
					return General_Error.Size_Mismatch
				}
				r.frames += 1
				r.state   = .Magic
				continue
			}
			stored := u32(header) & 0x8000_0000 != 0
			size   := int(u32(header) & 0x7FFF_FFFF)
			if size > r.block_max {
				return LZ4_Error.Block_Too_Large
			}
			data := lz4_read_bytes(r.z, size, &r.scratch) or_return
			r.consumed += i64(size)
			if r.checksummed {
				expected, e := compress.read_data(r.z, u32le)
				if e != nil {
					return General_Error.Stream_Too_Short
				}
				r.consumed += 4
				if xxhash.XXH32(data) != u32(expected) {
					return LZ4_Error.Block_Checksum_Failed
				}
			}
			overflow := Error(General_Error.Output_Too_Short)
			if r.content_size >= 0 || r.total_out >= 0 {
				overflow = General_Error.Size_Mismatch
			}
			start := r.written
			if r.independent {
				r.base = start
			}
			if stored {
				if i64(size) > room {
					return overflow
				}
				copy(r.window[start:], data)
				r.written = start + size
			} else {
				end, decode_err := lz4_decode(r.window[:start + need], start, r.base, data, r.dictionary, false, nil)
				if decode_err != nil {
					if decode_err == General_Error.Output_Too_Short {
						return overflow if need < r.block_max else LZ4_Error.Block_Too_Large
					}
					return decode_err
				}
				r.written = end
			}
			if r.content_hash {
				xxhash.XXH32_update(&r.digest, r.window[start:r.written])
			}
			r.total += i64(r.written - start)
			produced = true

		case .Legacy:
			if lz4_at_end(r.z) {
				r.frames += 1
				r.state   = .Magic
				continue
			}
			size_le, size_err := compress.peek_data(r.z, u32le)
			if size_err != nil {
				return General_Error.Stream_Too_Short
			}
			size := u32(size_le)
			if lz4_is_magic(size) {
				r.frames += 1
				r.state   = .Magic
				continue
			}
			room := r.limit - r.total if r.limit >= 0 else i64(max(int))
			need := int(min(i64(LEGACY_BLOCK_SIZE), room))
			if !lz4_stream_room(r, need, produced) {
				return nil
			}
			_ = compress.read_data(r.z, u32le) or_return
			if int(size) > LEGACY_BLOCK_SIZE + LEGACY_BLOCK_SIZE / 255 + 16 {
				return LZ4_Error.Block_Too_Large
			}
			data  := lz4_read_bytes(r.z, int(size), &r.scratch) or_return
			r.consumed += 4 + i64(size)
			start := r.written
			r.base = start
			end, decode_err := lz4_decode(r.window[:start + need], start, start, data, nil, false, nil)
			if decode_err != nil {
				if decode_err == General_Error.Output_Too_Short {
					if need >= LEGACY_BLOCK_SIZE {
						return LZ4_Error.Block_Too_Large
					}
					return General_Error.Size_Mismatch if r.total_out >= 0 else General_Error.Output_Too_Short
				}
				return decode_err
			}
			r.written = end
			r.total  += i64(end - start)
			produced  = true
		}
	}
}

@(private)
lz4_reader_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	r := (^Frame_Reader)(stream_data)
	#partial switch mode {
	case .Read:
		read, read_err := frame_reader_read(r, p)
		n = i64(read)
		if read_err != nil {
			io_err, is_io := read_err.(io.Error)
			err = io_err if is_io else .Unknown
		}
		return
	case .Destroy:
		frame_reader_destroy(r)
		return 0, nil
	case .Query:
		return io.query_utility({.Read, .Destroy, .Query})
	}
	return 0, .Unsupported
}

@(private, rodata)
LZ4_SHORT_OFFSET_PERIOD := [8]int{0, 8, 8, 9, 8, 10, 12, 14}
