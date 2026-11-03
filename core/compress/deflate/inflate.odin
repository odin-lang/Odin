package compress_deflate

import "base:builtin"
import "base:intrinsics"
import "core:compress"
import "core:hash"
import "core:simd"

inflate_raw  :: proc{inflate_raw_from_context, inflate_raw_from_bytes}
inflate_zlib :: proc{inflate_zlib_from_context, inflate_zlib_from_bytes}

inflate_raw_from_context :: proc(z: ^compress.Context, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator
	_, err = inflate_to_buffer(z, expected_output_size, max_output_size)
	return
}

inflate_zlib_from_context :: proc(z: ^compress.Context, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	context.allocator = allocator

	header, header_err := compress.read_data(z, [2]u8)
	if header_err != nil {
		return General_Error.Stream_Too_Short
	}
	cmf, flg := u32(header[0]), u32(header[1])
	if cmf & 0x0f != 8 {
		return General_Error.Unknown_Compression_Method
	}
	if cmf >> 4 > 7 {
		return ZLIB_Error.Unsupported_Window_Size
	}
	if flg & 0x20 != 0 {
		return ZLIB_Error.FDICT_Unsupported
	}
	if (cmf << 8 | flg) % 31 != 0 {
		return ZLIB_Error.Code_Buffer_Malformed
	}

	output := inflate_to_buffer(z, expected_output_size, max_output_size) or_return

	adler, adler_err := compress.read_data(z, u32be)
	if adler_err != nil {
		return General_Error.Stream_Too_Short
	}
	if hash.adler32(output) != u32(adler) {
		return General_Error.Checksum_Failed
	}
	return nil
}

inflate_raw_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return inflate_raw_from_context(&ctx, expected_output_size, max_output_size, allocator)
}

inflate_zlib_from_bytes :: proc(output: ^[dynamic]u8, input: []u8, expected_output_size := -1, max_output_size := compress.COMPRESS_OUTPUT_ALLOCATE_MAX, allocator := context.allocator) -> (err: Error) {
	input := input
	ctx   := compress.init_context_from_slice(&input, output=output)
	return inflate_zlib_from_context(&ctx, expected_output_size, max_output_size, allocator)
}

@(private)
inflate_load_u64 :: proc(p: [^]u8) -> u64 #no_bounds_check {
	return intrinsics.unaligned_load((^u64)(p))
}

@(private)
inflate_copy64 :: proc(destination, source: ^[^]u8) #no_bounds_check {
	n := intrinsics.unaligned_load((^u64)(source^))
	intrinsics.unaligned_store((^u64)(destination^), n)
	destination^ = destination[8:]
	source^ = source[8:]
}

@(private)
inflate_load_u8x16 :: proc(p: [^]u8) -> simd.u8x16 #no_bounds_check {
	return intrinsics.unaligned_load((^simd.u8x16)(p))
}

@(private)
inflate_store_u8x16 :: proc(d: [^]u8, v: simd.u8x16) #no_bounds_check {
	intrinsics.unaligned_store((^simd.u8x16)(d), v)
}

@(private)
inflate_splat_u8x16 :: proc(c: u8) -> simd.u8x16 #no_bounds_check {
	return simd.u8x16(c)
}

@(private)
inflate_write128 :: proc(destination: [^]u8, w: simd.u8x16) -> [^]u8 #no_bounds_check {
	inflate_store_u8x16(destination, w)
	return destination[16:]
}

@(private)
inflate_copy128 :: proc(destination, source: ^[^]u8) #no_bounds_check {
	n := inflate_load_u8x16(source^)
	inflate_store_u8x16(destination^, n)
	destination^ = destination[16:]
	source^ = source[16:]
}

@(private)
inflate_refill :: proc(s: ^Inflate, $STREAM: bool) -> (overrun: bool) #no_bounds_check {
	if intrinsics.expect(len(s.input) - s.position >= 8, true) {
		s.bit_buffer |= inflate_load_u64(raw_data(s.input)[s.position:]) << u64(s.bit_count)
		s.position += int((63 - s.bit_count) >> 3)
		s.bit_count |= 56 // bitcount in range [56,63]
		return false
	}
	when STREAM {
		s.input, s.position, s.bit_buffer, s.bit_count, s.eof = inflate_refill_stream(s.ctx, s.input, s.position, s.bit_buffer, s.bit_count, s.eof)
	} else {
		for s.bit_count < 56 {
			b: u64 = 0
			if s.position < len(s.input) {
				b = u64(s.input[s.position])
			}
			s.bit_buffer |= b << u64(s.bit_count)
			s.position += 1
			s.bit_count += 8
		}
	}
	return inflate_overrun(s)
}

@(private, cold)
inflate_refill_stream :: #force_no_inline proc(ctx: ^compress.Context, input: []u8, position: int, bit_buffer: u64, bit_count: i32, eof: bool) -> (new_input: []u8, new_position: int, new_bit_buffer: u64, new_bit_count: i32, new_eof: bool) #no_bounds_check {
	new_input, new_position, new_bit_buffer, new_bit_count, new_eof = input, position, bit_buffer, bit_count, eof
	if !new_eof {
		new_input, new_position, new_eof = inflate_fill(ctx, new_input, new_position, new_eof, 8)
		if len(new_input) - new_position >= 8 {
			new_bit_buffer |= inflate_load_u64(raw_data(new_input)[new_position:]) << u64(new_bit_count)
			new_position   += int((63 - new_bit_count) >> 3)
			new_bit_count  |= 56
			return
		}
	}
	for new_bit_count < 56 {
		b: u64 = 0
		if new_position < len(new_input) {
			b = u64(new_input[new_position])
		}
		new_bit_buffer |= b << u64(new_bit_count)
		new_position   += 1
		new_bit_count  += 8
	}
	return
}

@(private)
inflate_fill :: proc(ctx: ^compress.Context, input: []u8, position: int, eof: bool, need: int) -> (new_input: []u8, new_position: int, new_eof: bool) #no_bounds_check {
	if eof || position > len(input) {
		return input, position, true
	}
	ctx.window = input[position:]
	refill_error := compress.refill_window(ctx, need)
	return ctx.window, 0, refill_error != nil
}

@(private)
inflate_rewind :: proc(ctx: ^compress.Context, input: []u8, position: int) -> (new_input: []u8, new_position: int) #no_bounds_check {
	if position >= 0 {
		return input, position
	}
	ctx.window = input
	if !compress.rewind(ctx, -position) {
		return input, 0
	}
	return ctx.window, 0
}

@(private)
inflate_overrun :: proc(s: ^Inflate) -> bool #no_bounds_check {
	return (s.position - len(s.input)) * 8 > int(s.bit_count)
}

@(private)
inflate_peek :: proc(s: ^Inflate, count: i32) -> i32 #no_bounds_check {
	assert(count >= 0 && count <= 56)
	assert(count <= s.bit_count)
	return i32(s.bit_buffer & ((u64(1) << u64(count)) - 1))
}

@(private)
inflate_consume :: proc(s: ^Inflate, count: i32) #no_bounds_check {
	assert(count <= s.bit_count)
	s.bit_buffer >>= u64(count)
	s.bit_count -= count
}

@(private)
inflate_get_no_refill :: proc(s: ^Inflate, count: i32) -> i32 #no_bounds_check {
	result := inflate_peek(s, count)
	inflate_consume(s, count)
	return result
}

@(private)
inflate_get :: proc(s: ^Inflate, count: i32, $STREAM: bool) -> i32 #no_bounds_check {
	inflate_refill(s, STREAM)
	return inflate_get_no_refill(s, count)
}

@(private)
inflate_build_table :: proc(builder: ^Inflate_Table_Builder, table: []u32, table_bits: i32, counts: []i32) -> i32 {
	table_end: i32 = 0
	for {
		builder.count = counts[builder.length]
		if builder.count != 0 { break }
		builder.length += 1
	}
	table_end = i32(1) << u32(builder.length)
	for builder.length <= table_bits {
		for { // do {...} while (--gen->cnt);
			bit: u32 = 0
			table[builder.word] = (u32(builder.sorted[0]) << 16) | u32(builder.length)
			builder.sorted = builder.sorted[1:]
			if builder.word == table_end - 1 {
				for ; builder.length < table_bits; builder.length += 1 {
					copy(table[table_end:][:table_end], table[:table_end])
					table_end <<= 1
				}
				return 1
			}
			bit = u32(1) << log2(u32(builder.word ~ (table_end - 1)))
			builder.word &= i32(bit) - 1
			builder.word |= i32(bit)
			builder.count -= 1
			if builder.count == 0 { break }
		}
		for { // do {...} while (!(gen->cnt = cnt[gen->len]));
			builder.length += 1
			if builder.length <= table_bits {
				copy(table[table_end:][:table_end], table[:table_end])
				table_end <<= 1
			}
			builder.count = counts[builder.length]
			if builder.count != 0 { break }
		}
	}
	return 0
}

@(private)
inflate_build_sub_table :: proc(builder: ^Inflate_Table_Builder, table: []u32, table_bits: i32, counts: []i32) {
	sub_bits:   i32 = 0
	sub_start:  i32 = 0
	sub_prefix: i32 = -1
	table_end:  i32 = i32(1) << u32(table_bits)
	for {
		entry: u32
		bit, stride, i: i32
		// start new sub-table
		if (builder.word & ((i32(1) << u32(table_bits)) - 1)) != sub_prefix {
			used: i32 = 0
			sub_prefix = builder.word & ((i32(1) << u32(table_bits)) - 1)
			sub_start = table_end
			sub_bits = builder.length - table_bits
			used = builder.count
			for used < (i32(1) << u32(sub_bits)) {
				sub_bits += 1
				used = (used << 1) + counts[table_bits + sub_bits]
			}
			table_end = sub_start + (i32(1) << u32(sub_bits))
			table[sub_prefix] = (u32(sub_start) << 16) | 0x10 | u32(sub_bits & 0xf)
		}
		// fill sub-table
		entry = (u32(builder.sorted[0]) << 16) | u32((builder.length - table_bits) & 0xf)
		builder.sorted = builder.sorted[1:]
		i = sub_start + (builder.word >> u32(table_bits))
		stride = i32(1) << u32(builder.length - table_bits)
		for { // do {...} while (i < tbl_end);
			table[i] = entry
			i += stride
			if i >= table_end { break }
		}
		if builder.word == (i32(1) << u32(builder.length)) - 1 {
			return
		}
		bit = i32(1) << log2(u32(builder.word ~ ((i32(1) << u32(builder.length)) - 1)))
		builder.word &= bit - 1
		builder.word |= bit
		builder.count -= 1
		for builder.count == 0 {
			builder.length += 1
			builder.count = counts[builder.length]
		}
	}
}

@(private)
inflate_build :: proc(table: []u32, lengths: []u8, table_bits, maxlen, bad_symbol: i32) -> bool {
	i, used: i32
	sorted:    [288]i16 = ---
	counts:  [16]i32
	offsets: [16]i32
	builder: Inflate_Table_Builder
	builder.length = 1
	symbol_count := i32(len(lengths))

	for i = 0; i < symbol_count; i += 1 {
		counts[lengths[i]] += 1
	}
	offsets[1] = counts[0]
	for i = 1; i < maxlen; i += 1 {
		offsets[i + 1] = offsets[i] + counts[i]
		used = (used << 1) + counts[i]
	}
	used = (used << 1) + counts[i]
	for i = 0; i < symbol_count; i += 1 {
		sorted[offsets[lengths[i]]] = i16(i)
		offsets[lengths[i]] += 1
	}
	builder.sorted = sorted[offsets[0]:]

	if used > (i32(1) << u32(maxlen)) {
		return false
	}
	if used < (i32(1) << u32(maxlen)) {
		if bad_symbol < 0 {
			return false
		}
		if used != 0 && !(counts[1] == 1 && used == i32(1) << u32(maxlen - 1)) {
			return false
		}
		only := bad_symbol
		if used != 0 {
			only = i32(builder.sorted[0])
		}
		for i = 0; i < (i32(1) << u32(table_bits)); i += 1 {
			symbol := only if i & 1 == 0 else bad_symbol
			table[i] = (u32(symbol) << 16) | 1
		}
		return true
	}
	if inflate_build_table(&builder, table, table_bits, counts[:]) == 0 {
		inflate_build_sub_table(&builder, table, table_bits, counts[:])
	}
	return true
}

@(private)
inflate_decode :: proc(s: ^Inflate, table: []u32, bit_length: i32) -> i32 #no_bounds_check {
	index := inflate_peek(s, bit_length)
	key := table[index]
	if intrinsics.expect((key & 0x10) != 0, false) {
		// sub-table lookup
		len := i32(key & 0x0f)
		inflate_consume(s, bit_length)
		index = inflate_peek(s, len)
		key = table[((key >> 16) & 0xffff) + u32(index)]
	}
	inflate_consume(s, i32(key & 0x0f))
	return i32((key >> 16) & 0x0fff)
}

@(private)
inflate_grow :: proc(grow: ^[dynamic]u8, start, need, limit: int) -> (output: []u8, err: Error) #no_bounds_check {
	if grow == nil || need > limit {
		return nil, General_Error.Output_Too_Short
	}
	capacity := len(grow) - start
	step     := capacity if capacity < INFLATE_GROWTH_STEP else max(INFLATE_GROWTH_STEP, capacity / 4)
	non_zero_resize(grow, start + min(max(capacity + step, need), limit)) or_return
	return grow[start:], nil
}

@(private)
inflate_decompress :: proc(ctx: ^compress.Context, output: []u8, grow: ^[dynamic]u8, start, limit: int, $STREAM: bool) -> (written: int, err: Error) #no_bounds_check {
	output   := output
	capacity := len(output)

	fixed_loaded := false

	Inflate_State :: enum {Header, Stored, Fixed, Dynamic, Block}
	state := Inflate_State.Header
	s: Inflate
	last: i32 = 0

	s.ctx   = ctx
	s.input = ctx.window
	s.eof   = !STREAM

	defer {
		input, consumed := inflate_rewind(ctx, s.input, s.position - int(s.bit_count >> 3))
		ctx.window      = input[min(consumed, len(input)):]
		ctx.code_buffer = 0
		ctx.num_bits    = 0
	}

	for {
		switch state {
		case .Header:
			// block header
			type: i32 = 0
			if inflate_refill(&s, STREAM) { return written, General_Error.Stream_Too_Short }
			last = inflate_get_no_refill(&s, 1)
			type = inflate_get_no_refill(&s, 2)

			switch type {
			case 0x00: state = .Stored
			case 0x01: state = .Fixed
			case 0x02: state = .Dynamic
			case:      return written, Deflate_Error.BType_3
			}

		case .Stored:
			// uncompressed block
			len, inverted_length: u32
			inflate_get_no_refill(&s, s.bit_count & 7)
			len             = u32(u16(inflate_get_no_refill(&s, 16)))
			inverted_length = u32(u16(inflate_get_no_refill(&s, 16)))
			s.position -= int(s.bit_count / 8)
			s.bit_buffer = 0
			s.bit_count = 0
			when STREAM {
				s.input, s.position = inflate_rewind(s.ctx, s.input, s.position)
			}

			if u16(len) != u16(~inverted_length) {
				return written, Deflate_Error.Len_Nlen_Mismatch
			}
			if s.position > builtin.len(s.input) {
				return written, General_Error.Stream_Too_Short
			}

			when STREAM {
				remaining := int(len)
				for remaining > 0 {
					if s.position == builtin.len(s.input) {
						s.input, s.position, s.eof = inflate_fill(s.ctx, s.input, s.position, s.eof, 1)
						if s.position == builtin.len(s.input) {
							return written, General_Error.Stream_Too_Short
						}
					}
					n := min(remaining, builtin.len(s.input) - s.position)
					if n > capacity - written {
						output   = inflate_grow(grow, start, written + n, limit) or_return
						capacity = builtin.len(output)
					}
					copy(output[written:], s.input[s.position:][:n])
					s.position += n
					written    += n
					remaining  -= n
				}
			} else {
				if int(len) > builtin.len(s.input) - s.position {
					return written, General_Error.Stream_Too_Short
				}
				if int(len) > capacity - written {
					output   = inflate_grow(grow, start, written + int(len), limit) or_return
					capacity = builtin.len(output)
				}
				copy(output[written:], s.input[s.position:][:len])
				s.position += int(len)
				written    += int(len)
			}
			if last != 0 { return written, nil }
			state = .Header

		case .Fixed:
			// fixed huffman codes
			if !fixed_loaded {
				intrinsics.mem_copy_non_overlapping(&s.literals, &INFLATE_FIXED_LITERALS, size_of(INFLATE_FIXED_LITERALS))
				intrinsics.mem_copy_non_overlapping(&s.distances, &INFLATE_FIXED_DISTANCES, size_of(INFLATE_FIXED_DISTANCES))
				fixed_loaded = true
			}
			state = .Block

		case .Dynamic:
			// dynamic huffman codes
			n, i: i32
			precode_table:   [INFLATE_PRECODE_TABLE_SIZE]u32 = ---
			precode_lengths: [19]u8
			lengths:         [288 + 32]u8 = ---

			inflate_refill(&s, STREAM)
			{
				literal_count  := 257 + inflate_get_no_refill(&s, 5)
				distance_count := 1 + inflate_get_no_refill(&s, 5)
				precode_count  := 4 + inflate_get_no_refill(&s, 4)
				if literal_count > 286 || distance_count > 30 {
					return written, Deflate_Error.Huffman_Bad_Sizes
				}
				for n = 0; n < precode_count; n += 1 {
					precode_lengths[DEFLATE_PRECODE_ORDER[n]] = u8(inflate_get(&s, 3, STREAM))
				}
				if !inflate_build(precode_table[:], precode_lengths[:], 7, 7, -1) {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}

				// decode code lengths
				for n = 0; n < literal_count + distance_count; {
					symbol: i32 = 0
					inflate_refill(&s, STREAM)
					symbol = inflate_decode(&s, precode_table[:], 7)
					switch symbol {
					case 16:
						i = 3 + inflate_get(&s, 2, STREAM)
						if n == 0 || n + i > literal_count + distance_count { return written, Deflate_Error.Huffman_Bad_Code_Lengths }
						for ; i != 0; i, n = i - 1, n + 1 { lengths[n] = lengths[n - 1] }
					case 17:
						i = 3 + inflate_get(&s, 3, STREAM)
						if n + i > literal_count + distance_count { return written, Deflate_Error.Huffman_Bad_Code_Lengths }
						for ; i != 0; i, n = i - 1, n + 1 { lengths[n] = 0 }
					case 18:
						i = 11 + inflate_get(&s, 7, STREAM)
						if n + i > literal_count + distance_count { return written, Deflate_Error.Huffman_Bad_Code_Lengths }
						for ; i != 0; i, n = i - 1, n + 1 { lengths[n] = 0 }
					case:
						lengths[n] = u8(symbol)
						n += 1
					}
				}
				// build lit/dist tables
				if lengths[256] == 0 {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}
				if !inflate_build(s.literals[:], lengths[:literal_count], 10, 15, INFLATE_BAD_LITERAL) {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}
				if !inflate_build(s.distances[:], lengths[literal_count:][:distance_count], 8, 15, INFLATE_BAD_DISTANCE) {
					return written, Deflate_Error.Huffman_Bad_Code_Lengths
				}
				fixed_loaded = false
				state = .Block
			}

		case .Block:
			// decompress block
			block_loop: for {
				symbol: i32
				if inflate_refill(&s, STREAM) { return written, General_Error.Stream_Too_Short }
				symbol = inflate_decode(&s, s.literals[:], 10)
				if symbol < 256 {
					// literal
					if intrinsics.expect(written >= capacity, false) {
						output   = inflate_grow(grow, start, written + 1, limit) or_return
						capacity = builtin.len(output)
					}
					output[written] = u8(symbol)
					written += 1
					symbol = inflate_decode(&s, s.literals[:], 10)
					if symbol < 256 {
						if intrinsics.expect(written >= capacity, false) {
							output   = inflate_grow(grow, start, written + 1, limit) or_return
							capacity = builtin.len(output)
						}
						output[written] = u8(symbol)
						written += 1
						continue block_loop
					}
					if inflate_refill(&s, STREAM) { return written, General_Error.Stream_Too_Short }
				}
				// end of block
				if intrinsics.expect(symbol == 256, false) {
					if last != 0 {
						if inflate_overrun(&s) { return written, General_Error.Stream_Too_Short }
						return written, nil
					}
					state = .Header
					break block_loop
				}
				// match
				if intrinsics.expect(symbol >= 286, false) {
					// length codes 286 and 287 must not appear in compressed data
					return written, Deflate_Error.Bad_Huffman_Code
				}
				symbol -= 257
				{
					len             := inflate_get_no_refill(&s, i32(DEFLATE_LENGTH_EXTRA_BITS[symbol])) + i32(DEFLATE_LENGTH_BASE[symbol])
					distance_symbol := inflate_decode(&s, s.distances[:], 8)
					if intrinsics.expect(distance_symbol >= 30, false) { return written, Deflate_Error.Bad_Huffman_Code }
					distance        := inflate_get_no_refill(&s, i32(DEFLATE_DISTANCE_EXTRA_BITS[distance_symbol])) + i32(DEFLATE_DISTANCE_BASE[distance_symbol])
					if intrinsics.expect(int(distance) > written, false) { return written, Deflate_Error.Bad_Distance }
					match_end := written + int(len)
					if intrinsics.expect(match_end > capacity, false) {
						output   = inflate_grow(grow, start, match_end, limit) or_return
						capacity = builtin.len(output)
					}
					destination := raw_data(output)[written:]
					source      := raw_data(output)[written - int(distance):]
					out         := raw_data(output)[match_end:]
					written = match_end

					if intrinsics.expect(capacity - match_end >= 16 * 3, true) {
						if distance >= 16 {
							// simd copy match
							inflate_copy128(&destination, &source)
							inflate_copy128(&destination, &source)
							for {
								inflate_copy128(&destination, &source)
								if !(uintptr(destination) < uintptr(out)) { break }
							}
						} else if distance >= 8 {
							// word copy match
							inflate_copy64(&destination, &source)
							inflate_copy64(&destination, &source)
							for {
								inflate_copy64(&destination, &source)
								if !(uintptr(destination) < uintptr(out)) { break }
							}
						} else if distance == 1 {
							// rle match copying
							w := inflate_splat_u8x16(source[0])
							destination = inflate_write128(destination, w)
							destination = inflate_write128(destination, w)
							for {
								destination = inflate_write128(destination, w)
								if !(uintptr(destination) < uintptr(out)) { break }
							}
						} else {
							// byte copy match
							destination[0] = source[0]; destination = destination[1:]; source = source[1:]
							destination[0] = source[0]; destination = destination[1:]; source = source[1:]
							for {
								destination[0] = source[0]; destination = destination[1:]; source = source[1:]
								if !(uintptr(destination) < uintptr(out)) { break }
							}
						}
					} else {
						destination[0] = source[0]; destination = destination[1:]; source = source[1:]
						destination[0] = source[0]; destination = destination[1:]; source = source[1:]
						for {
							destination[0] = source[0]; destination = destination[1:]; source = source[1:]
							if !(uintptr(destination) < uintptr(out)) { break }
						}
					}
				}
			}
		}
	}
	return written, nil
}

@(private)
inflate_initial_size :: proc(size_hint, input_size: int) -> (size: int) #no_bounds_check {
	bound := -1
	if input_size >= 0 && input_size < max(int) / INFLATE_EXPANSION_MAX {
		bound = INFLATE_EXPANSION_MAX * input_size
	}
	if size_hint > 0 {
		size = min(size_hint, bound) if bound >= 0 else min(size_hint, INFLATE_INITIAL_SIZE_MAX)
		return max(size, INFLATE_INITIAL_SIZE_MIN)
	}

	size = INFLATE_STREAM_INITIAL_SIZE
	if input_size >= 0 {
		size = deflate_bound(input_size)
		if size < 0 {
			size = INFLATE_INITIAL_SIZE_MAX
		}
	}
	if bound >= 0 {
		size = min(size, bound)
	}
	return clamp(size, INFLATE_INITIAL_SIZE_MIN, INFLATE_INITIAL_SIZE_MAX)
}

@(private)
inflate_to_buffer :: proc(z: ^compress.Context, expected_output_size, max_output_size: int, start := 0, size_hint := -1) -> (output: []u8, err: Error) #no_bounds_check {
	if z.output == nil {
		return nil, General_Error.Incompatible_Options
	}
	expected_output_size := expected_output_size
	if expected_output_size <= 0 && z.size_unpacked > 0 && z.size_unpacked <= i64(max(int)) {
		expected_output_size = int(z.size_unpacked)
	}

	limit := max_output_size
	hint  := size_hint - start if size_hint > start else -1
	if expected_output_size > 0 {
		if expected_output_size > limit {
			return nil, General_Error.Output_Too_Short
		}
		limit = expected_output_size
		hint  = expected_output_size - start
	}
	limit -= start
	if limit < 0 {
		return nil, General_Error.Output_Too_Short
	}

	input_size := -1
	if compress.is_memory_context(z) {
		input_size = len(z.window)
	} else if n, size_err := compress.size(z); size_err == nil && n <= i64(max(int)) {
		input_size = int(n)
	}

	buffer := z.output
	non_zero_resize(buffer, start + min(inflate_initial_size(hint, input_size), limit)) or_return

	written: int
	if compress.is_memory_context(z) {
		written, err = inflate_decompress(z, buffer[start:], buffer, start, limit, false)
	} else {
		written, err = inflate_decompress(z, buffer[start:], buffer, start, limit, true)
	}
	non_zero_resize(buffer, start + written)
	z.bytes_written = i64(start + written)
	return buffer[:start + written], err
}
